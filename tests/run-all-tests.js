#!/usr/bin/env node

/**
 * Main Test Runner for Redis Mastering Course
 * Runs comprehensive integration tests for all 15 labs
 */

const TestUtils = require('./test-utils');
const day1Tests = require('./day1-labs-test');
const day2Tests = require('./day2-labs-test');
const day3Tests = require('./day3-labs-test');
const path = require('path');

const testUtils = new TestUtils();

/**
 * Parse command line arguments
 */
function parseArgs() {
    const args = process.argv.slice(2);
    const options = {
        day: null,
        lab: null,
        saveResults: true,
        verbose: false
    };

    args.forEach(arg => {
        if (arg.startsWith('--day=')) {
            options.day = parseInt(arg.split('=')[1]);
        } else if (arg.startsWith('--lab=')) {
            options.lab = parseInt(arg.split('=')[1]);
        } else if (arg === '--no-save') {
            options.saveResults = false;
        } else if (arg === '--verbose' || arg === '-v') {
            options.verbose = true;
        } else if (arg === '--help' || arg === '-h') {
            printHelp();
            process.exit(0);
        }
    });

    return options;
}

/**
 * Print help message
 */
function printHelp() {
    console.log(`
╔════════════════════════════════════════════════════════════════════════════╗
║              Redis Mastering Course - Integration Test Suite              ║
╚════════════════════════════════════════════════════════════════════════════╝

USAGE:
  node tests/run-all-tests.js [OPTIONS]

OPTIONS:
  --day=<1|2|3>        Run tests for specific day only
  --lab=<1-15>         Run tests for specific lab only
  --no-save            Don't save test results to file
  --verbose, -v        Enable verbose output
  --help, -h           Show this help message

EXAMPLES:
  # Run all tests
  npm test

  # Run Day 1 tests only
  npm run test:day1

  # Run Day 2 tests only
  npm run test:day2

  # Run Day 3 tests only
  npm run test:day3

  # Run specific lab
  node tests/run-all-tests.js --lab=7

  # Run specific day with verbose output
  node tests/run-all-tests.js --day=2 --verbose

NPM SCRIPTS:
  npm test              Run all tests
  npm run test:day1     Run Day 1 tests (Labs 1-5)
  npm run test:day2     Run Day 2 tests (Labs 6-10)
  npm run test:day3     Run Day 3 tests (Labs 11-15)
  npm run test:setup    Setup test environment
  npm run test:cleanup  Cleanup test environment

PREREQUISITES:
  - Redis server running on localhost:6379
  - Node.js 18+ installed
  - All lab dependencies installed
  - Docker (for Lab 15 cluster tests)

For more information, see tests/README.md
`);
}

/**
 * Print test header
 */
function printHeader() {
    console.log('\n╔════════════════════════════════════════════════════════════════════════════╗');
    console.log('║                                                                            ║');
    console.log('║              REDIS MASTERING COURSE - INTEGRATION TEST SUITE              ║');
    console.log('║                                                                            ║');
    console.log('║                            All 15 Labs (3 Days)                            ║');
    console.log('║                                                                            ║');
    console.log('╚════════════════════════════════════════════════════════════════════════════╝');
    console.log(`\n⏰ Test started: ${new Date().toLocaleString()}\n`);
}

/**
 * Run specific lab test
 */
async function runSpecificLab(labNumber) {
    console.log(`\n╔════════════════════════════════════════════════════════════════════════════╗`);
    console.log(`║                            Lab ${labNumber} Integration Test                             ║`);
    console.log(`╚════════════════════════════════════════════════════════════════════════════╝\n`);

    let testFunction;

    switch (labNumber) {
        case 1: testFunction = day1Tests.testLab1; break;
        case 2: testFunction = day1Tests.testLab2; break;
        case 3: testFunction = day1Tests.testLab3; break;
        case 4: testFunction = day1Tests.testLab4; break;
        case 5: testFunction = day1Tests.testLab5; break;
        case 6: testFunction = day2Tests.testLab6; break;
        case 7: testFunction = day2Tests.testLab7; break;
        case 8: testFunction = day2Tests.testLab8; break;
        case 9: testFunction = day2Tests.testLab9; break;
        case 10: testFunction = day2Tests.testLab10; break;
        case 11: testFunction = day3Tests.testLab11; break;
        case 12: testFunction = day3Tests.testLab12; break;
        case 13: testFunction = day3Tests.testLab13; break;
        case 14: testFunction = day3Tests.testLab14; break;
        case 15: testFunction = day3Tests.testLab15; break;
        default:
            console.error(`\x1b[31m✗\x1b[0m Invalid lab number: ${labNumber}`);
            console.error(`  Valid lab numbers are 1-15`);
            process.exit(1);
    }

    const result = await testFunction();
    return {
        totalPassed: result.passed,
        totalFailed: result.failed,
        labs: [{ lab: labNumber, ...result }]
    };
}

/**
 * Run all tests or filtered tests based on options
 */
async function runTests() {
    const options = parseArgs();
    printHeader();

    // Check Redis connection before starting
    console.log('Checking Redis connection...');
    const redisRunning = await testUtils.isRedisRunning();

    if (!redisRunning) {
        console.error('\x1b[31m✗\x1b[0m Redis is not running on localhost:6379');
        console.error('  Please start Redis before running tests:');
        console.error('    - Using Docker: docker run -d -p 6379:6379 redis:latest');
        console.error('    - Using local Redis: redis-server');
        process.exit(1);
    }

    console.log('\x1b[32m✓\x1b[0m Redis connection successful\n');

    const allResults = {
        totalPassed: 0,
        totalFailed: 0,
        days: []
    };

    try {
        // Run specific lab
        if (options.lab) {
            const result = await runSpecificLab(options.lab);
            allResults.totalPassed = result.totalPassed;
            allResults.totalFailed = result.totalFailed;
            allResults.days = [{ day: Math.ceil(options.lab / 5), ...result }];
        }
        // Run specific day
        else if (options.day) {
            let result;
            switch (options.day) {
                case 1:
                    result = await day1Tests.runDay1Tests();
                    break;
                case 2:
                    result = await day2Tests.runDay2Tests();
                    break;
                case 3:
                    result = await day3Tests.runDay3Tests();
                    break;
                default:
                    console.error(`\x1b[31m✗\x1b[0m Invalid day: ${options.day}`);
                    console.error(`  Valid days are 1, 2, or 3`);
                    process.exit(1);
            }
            allResults.totalPassed = result.totalPassed;
            allResults.totalFailed = result.totalFailed;
            allResults.days = [{ day: options.day, ...result }];
        }
        // Run all tests
        else {
            console.log('Running all tests for 3 days (15 labs)...\n');

            // Day 1 tests
            const day1Result = await day1Tests.runDay1Tests();
            allResults.totalPassed += day1Result.totalPassed;
            allResults.totalFailed += day1Result.totalFailed;
            allResults.days.push({ day: 1, ...day1Result });

            // Day 2 tests
            const day2Result = await day2Tests.runDay2Tests();
            allResults.totalPassed += day2Result.totalPassed;
            allResults.totalFailed += day2Result.totalFailed;
            allResults.days.push({ day: 2, ...day2Result });

            // Day 3 tests
            const day3Result = await day3Tests.runDay3Tests();
            allResults.totalPassed += day3Result.totalPassed;
            allResults.totalFailed += day3Result.totalFailed;
            allResults.days.push({ day: 3, ...day3Result });
        }

    } catch (error) {
        console.error('\n\x1b[31m✗ Test execution failed:\x1b[0m', error.message);
        if (options.verbose) {
            console.error(error.stack);
        }
        process.exit(1);
    }

    // Print final summary
    printFinalSummary(allResults);

    // Save results to file
    if (options.saveResults) {
        const timestamp = new Date().toISOString().replace(/:/g, '-').replace(/\..+/, '');
        const resultsPath = path.join(process.cwd(), 'tests', 'results', `test-results-${timestamp}.json`);
        await testUtils.saveTestResults(resultsPath);
    }

    // Exit with appropriate code
    process.exit(allResults.totalFailed === 0 ? 0 : 1);
}

/**
 * Print final summary
 */
function printFinalSummary(results) {
    console.log('\n');
    console.log('╔════════════════════════════════════════════════════════════════════════════╗');
    console.log('║                            FINAL TEST SUMMARY                              ║');
    console.log('╚════════════════════════════════════════════════════════════════════════════╝');

    // Overall summary
    const total = results.totalPassed + results.totalFailed;
    const percentage = total > 0 ? ((results.totalPassed / total) * 100).toFixed(2) : 0;

    console.log(`\nTotal Tests Run: ${total}`);
    console.log(`Passed: \x1b[32m${results.totalPassed}\x1b[0m`);
    console.log(`Failed: \x1b[31m${results.totalFailed}\x1b[0m`);
    console.log(`Success Rate: ${percentage}%`);

    // Day-by-day summary
    if (results.days.length > 1) {
        console.log('\n' + '─'.repeat(80));
        console.log('Day-by-Day Summary:');
        console.log('─'.repeat(80));

        results.days.forEach(day => {
            const dayTotal = day.totalPassed + day.totalFailed;
            const dayPercentage = dayTotal > 0 ? ((day.totalPassed / dayTotal) * 100).toFixed(2) : 0;
            const status = day.totalFailed === 0 ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m';

            console.log(`\n${status} Day ${day.day}: ${day.totalPassed}/${dayTotal} tests passed (${dayPercentage}%)`);

            if (day.labs) {
                day.labs.forEach(lab => {
                    const labTotal = lab.passed + lab.failed;
                    const labStatus = lab.failed === 0 ? '\x1b[32m✓\x1b[0m' : '\x1b[31m✗\x1b[0m';
                    console.log(`  ${labStatus} Lab ${lab.lab}: ${lab.passed}/${labTotal} tests passed`);
                });
            }
        });
    }

    // Failed tests detail
    if (results.totalFailed > 0) {
        console.log('\n' + '═'.repeat(80));
        console.log('\x1b[31mFAILED TESTS REQUIRE ATTENTION\x1b[0m');
        console.log('═'.repeat(80));
        console.log('\nPlease review the test output above for details on failed tests.');
        console.log('Common issues:');
        console.log('  - Missing lab directories or files');
        console.log('  - Lab dependencies not installed (run: npm run test:setup)');
        console.log('  - Redis server not running or misconfigured');
        console.log('  - Docker not running (required for Lab 15)');
    } else {
        console.log('\n' + '═'.repeat(80));
        console.log('\x1b[32m✓ ALL TESTS PASSED! 🎉\x1b[0m');
        console.log('═'.repeat(80));
        console.log('\nAll labs are functioning correctly. The course is ready for delivery!');
    }

    console.log(`\n⏰ Test completed: ${new Date().toLocaleString()}`);
    console.log('');
}

// Run tests
if (require.main === module) {
    runTests().catch(error => {
        console.error('\n\x1b[31m✗ Fatal error:\x1b[0m', error.message);
        console.error(error.stack);
        process.exit(1);
    });
}

module.exports = {
    runTests,
    runSpecificLab,
    parseArgs
};
