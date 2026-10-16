<?php

declare(strict_types=1);

namespace Tests\Support\Core\Load;

use InvalidArgumentException;
use RuntimeException;
use Symfony\Component\Process\Exception\ProcessTimedOutException;
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
                } elseif (preg_match('/\A--(scenario|endpoint|config)=([^\r\n]+)\z/', $argument, $matches) === 1) {
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
                fwrite(STDOUT, 'Usage: composer test:load -- --list|--list-tests [--endpoint=/api/expenses] [--scenario=expense-pages]'.PHP_EOL);
                fwrite(STDOUT, 'To run, select one scenario or endpoint and use --config=/private/load.json or TROCADO_LOAD_CONFIG. URL/token/concurrency/duration belong in that private file outside the repository.'.PHP_EOL);

                return 0;
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
                    fwrite(STDOUT, json_encode(['scenario' => $scenario->value, 'endpoint' => $scenario->endpoint(), 'file' => $scenario->file()], JSON_THROW_ON_ERROR | JSON_UNESCAPED_SLASHES).PHP_EOL);
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

            if ((! isset($options['scenario']) && ! isset($options['endpoint'])) || count($scenarios) !== 1) {
                throw new InvalidArgumentException;
            }

            $path = $options['config'] ?? getenv('TROCADO_LOAD_CONFIG');
            if (! is_string($path) || $path === '') {
                throw new RuntimeException('Load requires TROCADO_LOAD_CONFIG with a prepared dedicated target and its Bearer token.');
            }
            $configuration = LoadConfiguration::fromFile($path, $this->root);
            $process = new Process([PHP_BINARY, '-d', 'memory_limit=512M', $this->root.'/vendor/bin/pest', '--configuration='.$this->root.'/phpunit.load.xml', $scenarios[0]->file(), '--compact'], $this->root, ['TROCADO_LOAD_RUN' => '1', 'TROCADO_LOAD_CONFIG' => $path]);
            $process->setTimeout($configuration->durationSeconds + 75);
            $process->run();
            fwrite(STDOUT, $configuration->redact($process->getOutput()));
            fwrite(STDERR, $configuration->redact($process->getErrorOutput()));

            return $process->getExitCode() ?? 2;
        } catch (InvalidArgumentException) {
            fwrite(STDERR, 'Invalid Load selection. Use --help; values and unknown options are not echoed.'.PHP_EOL);

            return 1;
        } catch (ProcessTimedOutException) {
            fwrite(STDERR, 'Load process exceeded its deadline.'.PHP_EOL);

            return 2;
        } catch (RuntimeException) {
            fwrite(STDERR, 'Load refused: verify the private configuration, dedicated target and process deadline. No automatic provisioning or cleanup is performed.'.PHP_EOL);

            return 2;
        } catch (Throwable) {
            fwrite(STDERR, 'Load command failed; no automatic provisioning or resource cleanup is performed.'.PHP_EOL);

            return 2;
        }
    }
}
