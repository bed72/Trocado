<?php

declare(strict_types=1);

namespace App\Identity\Application\UseCases;

use App\Core\Application\Ports\ObservabilityPort;
use App\Identity\Application\Data\SignInOutput;
use App\Identity\Application\Ports\SignInPort;
use SensitiveParameter;

final readonly class SignInUseCase
{
    public function __construct(private SignInPort $signInPort, private ObservabilityPort $observabilityPort) {}

    public function execute(string $email, #[SensitiveParameter] string $password): SignInOutput
    {
        $output = $this->signInPort->issue(email: $email, password: $password);

        $this->observabilityPort->emit('identity.signed_in', ['user_id' => $output->userId]);

        return $output;
    }
}
