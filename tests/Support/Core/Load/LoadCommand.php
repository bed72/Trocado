<?php

declare(strict_types=1);

namespace Tests\Support\Core\Load;

use InvalidArgumentException;
use RuntimeException;
use Symfony\Component\Process\Process;
use Throwable;

use function array_key_exists;
use function in_array;

final readonly class LoadCommand
{
    public function __construct(private string $root) {}

    /** @param list<string> $arguments */
    public function run(array $arguments): int
    {
        try {
            $options = [];
            foreach ($arguments as $argument) {
                if (in_array($argument, ['--help', '--list', '--list-tests'], true)) {
                    $name = substr($argument, 2);
                    $value = true;
                } elseif (preg_match('/\A--(scenario|endpoint|objective)=([^\r\n]+)\z/', $argument, $matches) === 1) {
                    [, $name, $value] = $matches;
                } else {
                    throw new InvalidArgumentException;
                }
                if (array_key_exists($name, $options)) {
                    throw new InvalidArgumentException;
                }
                $options[$name] = $value;
            }

            if (isset($options['help'])) {
                fwrite(STDOUT, 'Usage: composer test:load -- --list|--list-tests [--endpoint=/api/expenses] [--scenario=expense-pages] [--objective=capacity|regression]'.PHP_EOL);
                fwrite(STDOUT, 'Execution requires one scenario, an objective and TROCADO_LOAD_CONFIG (private JSON outside the repository). No URL, token or credential CLI options.'.PHP_EOL);

                return 0;
            }

            if (isset($options['objective']) && ! in_array($options['objective'], ['capacity', 'regression'], true)) {
                throw new InvalidArgumentException;
            }
            if (isset($options['list'], $options['list-tests'])) {
                throw new InvalidArgumentException;
            }

            $scenarios = array_values(array_filter(LoadScenarioEnum::cases(), static fn (LoadScenarioEnum $scenario): bool => (! isset($options['scenario']) || $options['scenario'] === $scenario->value)
                && (! isset($options['endpoint']) || $options['endpoint'] === $scenario->endpoint())));
            if ($scenarios === []) {
                throw new InvalidArgumentException;
            }

            if (isset($options['list'])) {
                foreach ($scenarios as $scenario) {
                    fwrite(STDOUT, json_encode(['scenario' => $scenario->value, 'endpoint' => $scenario->endpoint(), 'file' => $scenario->file(), 'state' => 'Blocked'], JSON_THROW_ON_ERROR | JSON_UNESCAPED_SLASHES).PHP_EOL);
                }

                return 0;
            }

            if (isset($options['list-tests'])) {
                $process = new Process([PHP_BINARY, $this->root.'/vendor/bin/pest', '--configuration='.$this->root.'/phpunit.load.xml', '--list-tests', ...array_map(static fn (LoadScenarioEnum $scenario): string => $scenario->file(), $scenarios)], $this->root);
                $process->setTimeout(15);

                return $process->run(static function (string $type, string $buffer): void {
                    fwrite($type === Process::ERR ? STDERR : STDOUT, $buffer);
                });
            }

            if (! isset($options['scenario'], $options['objective']) || count($scenarios) !== 1) {
                throw new InvalidArgumentException;
            }

            fwrite(STDOUT, json_encode(['scenario' => $scenarios[0]->value, 'objective' => $options['objective'], 'phase' => LoadPhaseEnum::Preflight->value, 'state' => LoadStateEnum::Blocked->value], JSON_THROW_ON_ERROR).PHP_EOL);
            LoadEngineGate::assertReady();
        } catch (InvalidArgumentException) {
            fwrite(STDERR, 'Invalid Load selection. Use --help; values and unknown options are not echoed.'.PHP_EOL);

            return 1;
        } catch (RuntimeException $exception) {
            if ($exception->getMessage() === LoadEngineGate::REASON) {
                fwrite(STDERR, $exception->getMessage().PHP_EOL);
            } else {
                fwrite(STDERR, 'Blocked: Load discovery failed; no campaign was started.'.PHP_EOL);
            }

            return 2;
        } catch (Throwable) {
            fwrite(STDERR, 'Blocked: Load command failed; no campaign was started.'.PHP_EOL);

            return 2;
        }
    }
}
