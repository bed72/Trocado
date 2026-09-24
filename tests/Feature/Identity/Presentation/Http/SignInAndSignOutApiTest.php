<?php

declare(strict_types=1);

use App\Identity\Infrastructure\Persistence\Models\UserModel;
use Illuminate\Support\Facades\Date;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Hash;
use Illuminate\Support\Str;
use Laravel\Sanctum\PersonalAccessToken;

it('issues a non-cacheable Sanctum access token for canonical credentials', function (): void {
    Date::setTestNow('2026-09-21 10:00:00');

    try {
        $userId = signUpIdentityByApi($this, password: ' Abc123 ');
        $response = $this->postJson(
            route('authentication.api.sign-in'),
            authenticationSignInPayload(email: '  MARIA@EXAMPLE.COM  ', password: ' Abc123 '),
        );

        $response->assertOk()
            ->assertHeader('Content-Type', 'application/vnd.api+json')
            ->assertHeader('Cache-Control', 'no-store, private')
            ->assertHeader('Pragma', 'no-cache')
            ->assertJsonPath('data.type', 'access-tokens')
            ->assertJsonPath('data.attributes.token_type', 'Bearer')
            ->assertJsonPath('data.attributes.expires_at', '2026-09-21T12:00:00+00:00')
            ->assertJsonPath('data.relationships.user.data.type', 'users')
            ->assertJsonPath('data.relationships.user.data.id', (string) $userId);

        $plainTextToken = $response->json('data.attributes.token');
        $tokenId = $response->json('data.id');
        expect($plainTextToken)->toBeString()->not->toBeEmpty()
            ->and($tokenId)->toBeString();

        $storedToken = PersonalAccessToken::query()->findOrFail($tokenId);
        expect($storedToken->token)->toBe(hash('sha256', Str::after($plainTextToken, '|')))
            ->and($storedToken->token)->not->toContain($plainTextToken)
            ->and($storedToken->abilities)->toBe([])
            ->and($storedToken->expires_at?->toAtomString())->toBe('2026-09-21T12:00:00+00:00');
    } finally {
        Date::setTestNow();
    }
});

it('creates independent tokens and revokes only the current bearer token', function (): void {
    signUpIdentityByApi($this);
    $firstToken = $this->postJson(
        route('authentication.api.sign-in'),
        authenticationSignInPayload(),
    )->assertOk()->json('data.attributes.token');
    $secondToken = $this->postJson(
        route('authentication.api.sign-in'),
        authenticationSignInPayload(),
    )->assertOk()->json('data.attributes.token');

    expect($firstToken)->not->toBe($secondToken);
    $this->assertDatabaseCount('personal_access_tokens', 2);

    $this->withToken($firstToken)->deleteJson(route('authentication.api.sign-out'))->assertNoContent();
    $this->assertDatabaseCount('personal_access_tokens', 1);

    app('auth')->forgetGuards();
    $this->withToken($firstToken)->deleteJson(route('authentication.api.sign-out'))
        ->assertUnauthorized()
        ->assertHeader('Content-Type', 'application/vnd.api+json');
    app('auth')->forgetGuards();
    $this->withToken($secondToken)->deleteJson(route('authentication.api.sign-out'))->assertNoContent();
    $this->assertDatabaseCount('personal_access_tokens', 0);
});

it('accepts an issued bearer token on private application routes', function (): void {
    $userId = signUpIdentityByApi($this);
    $token = $this->postJson(
        route('authentication.api.sign-in'),
        authenticationSignInPayload(),
    )->assertOk()->json('data.attributes.token');

    $this->withToken($token)->getJson(route('users.get', ['user' => $userId]))
        ->assertOk()
        ->assertJsonPath('data.id', (string) $userId);
});

it('returns the same generic response for every invalid credential condition', function (string $condition): void {
    $email = 'maria@example.com';
    $password = 'Correct1';

    if ($condition === 'invalid email') {
        $email = 'invalid';
    } elseif ($condition === 'overlong email') {
        $email = str_repeat('a', 256);
    } elseif ($condition === 'wrong password') {
        signUpIdentityByApi($this);
        $password = 'incorrect password';
    } elseif ($condition === 'irrecoverable password') {
        authenticationCreateHistoricalUser(password: Str::random(72));
    }

    $this->postJson(
        route('authentication.api.sign-in'),
        authenticationSignInPayload(email: $email, password: $password),
    )->assertUnauthorized()
        ->assertHeader('Content-Type', 'application/vnd.api+json')
        ->assertExactJson(['errors' => [[
            'status' => '401',
            'title' => 'Credenciais inválidas',
            'detail' => 'As credenciais informadas são inválidas.',
        ]]]);

    $this->assertDatabaseCount('personal_access_tokens', 0);
})->with([
    'malformed email' => ['invalid email'],
    'overlong email' => ['overlong email'],
    'missing user' => ['missing user'],
    'wrong password' => ['wrong password'],
    'backfilled user' => ['irrecoverable password'],
]);

it('returns JSON API validation errors only for invalid document structure', function (): void {
    $this->postJson(route('authentication.api.sign-in'), [
        'data' => [
            'type' => 'access-tokens',
            'attributes' => ['email' => 'maria@example.com'],
        ],
    ])->assertUnprocessable()
        ->assertHeader('Content-Type', 'application/vnd.api+json')
        ->assertJsonFragment(['source' => ['pointer' => '/data/attributes/password']]);
});

it('rehashes a valid password through the configured Laravel provider', function (): void {
    $userId = DB::table('users')->insertGetId([
        'name' => 'Maria',
        'email' => 'maria@example.com',
        'password' => Hash::make('Correct1', ['rounds' => 5]),
        'created_at' => now(),
        'updated_at' => now(),
    ]);
    $user = UserModel::query()->findOrFail($userId);
    $oldHash = $user->getAuthPassword();

    $this->postJson(
        route('authentication.api.sign-in'),
        authenticationSignInPayload(),
    )->assertOk();

    $newHash = $user->fresh()->getAuthPassword();
    expect($newHash)->not->toBe($oldHash)
        ->and(Hash::check('Correct1', $newHash))->toBeTrue()
        ->and(password_get_info($newHash)['options']['cost'])->toBe(4);
});

it('rejects expired tokens independently of physical pruning', function (): void {
    Date::setTestNow('2026-09-21 10:00:00');

    try {
        signUpIdentityByApi($this);
        $token = $this->postJson(
            route('authentication.api.sign-in'),
            authenticationSignInPayload(),
        )->assertOk()->json('data.attributes.token');

        Date::setTestNow(Date::now()->addMinutes(121));

        $this->withToken($token)->deleteJson(route('authentication.api.sign-out'))
            ->assertUnauthorized()
            ->assertHeader('Content-Type', 'application/vnd.api+json');
        $this->assertDatabaseCount('personal_access_tokens', 1);

        $this->artisan('sanctum:prune-expired', ['--hours' => 0])->assertSuccessful();
        $this->assertDatabaseCount('personal_access_tokens', 0);

        $this->withToken($token)->deleteJson(route('authentication.api.sign-out'))->assertUnauthorized();
    } finally {
        Date::setTestNow();
    }
});

it('returns a JSON API unauthorized response without a bearer token', function (): void {
    $this->deleteJson(route('authentication.api.sign-out'))
        ->assertUnauthorized()
        ->assertHeader('Content-Type', 'application/vnd.api+json')
        ->assertExactJson(['errors' => [[
            'status' => '401',
            'title' => 'Não autenticado',
            'detail' => 'É necessário autenticar-se para acessar este recurso.',
        ]]]);
});

it('does not accept a web session without a bearer token', function (): void {
    $userId = signUpIdentityByApi($this);

    $this->actingAs(UserModel::query()->findOrFail($userId), 'web')
        ->deleteJson(route('authentication.api.sign-out'))
        ->assertUnauthorized()
        ->assertHeader('Content-Type', 'application/vnd.api+json');
});

function authenticationCreateHistoricalUser(string $password): UserModel
{
    return UserModel::query()->create([
        'name' => 'Maria',
        'email' => 'maria@example.com',
        'password' => $password,
    ]);
}

function authenticationSignInPayload(
    string $email = 'maria@example.com',
    string $password = 'Correct1',
): array {
    return [
        'data' => [
            'type' => 'access-tokens',
            'attributes' => [
                'email' => $email,
                'password' => $password,
            ],
        ],
    ];
}
