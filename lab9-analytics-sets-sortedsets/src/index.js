const chalk = require('chalk');
const { runFullAnalytics } = require('./analytics-dashboard');

console.log(chalk.cyan.bold('\n🚀 Lab 9: Analytics with Sets and Sorted Sets\n'));
console.log(chalk.gray('═'.repeat(60)));
console.log('\nWelcome to the Analytics Lab!');
console.log('\nAvailable commands:');
console.log('  npm test              - Test Redis connection');
console.log('  npm run load-data     - Load sample data');
console.log('  npm run segmentation  - Run customer segmentation');
console.log('  npm run leaderboard   - Display agent leaderboards');
console.log('  npm run risk-analysis - Analyze risk distribution');
console.log('  npm run coverage      - Analyze coverage gaps');
console.log('  npm run analytics     - Run full analytics dashboard');
console.log('\nStarting full analytics dashboard...\n');

// Run analytics
runFullAnalytics().catch(console.error);
