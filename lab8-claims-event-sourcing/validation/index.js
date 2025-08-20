/**
 * Lab 8 Validation Module
 * Entry point for all validation utilities
 */

const SetupValidator = require('./validate-setup');

module.exports = {
    SetupValidator,
    
    async validateSetup() {
        const validator = new SetupValidator();
        return await validator.validate();
    },
    
    async quickCheck() {
        const validator = new SetupValidator();
        // Run basic checks only
        validator.checkNodeJs();
        validator.checkProjectStructure();
        validator.checkPackageJson();
        validator.displayResults();
        return validator.errors.length === 0;
    }
};
