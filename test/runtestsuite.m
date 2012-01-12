% N.B. these values should match in TestPldapsBase
connection_file = 'ovation/matlab_fd.connection';
username = 'TestUser';
password = 'password';

pdsFile = 'fixtures/pat120811a_decision2_16.PDS'; % Our only tie to test fixture
 
% Delete the test database if it exists
if(exist(connection_file, 'file') ~= 0)
    ovation.util.deleteLocalOvationDatabase(connection_file, true);
end

% Create a test database
system('mkdir -p ovation');

connection_file = ovation.util.createLocalOvationDatabase('ovation', ...
    'matlab_fd',...
    username,...
    password,...
    'license.txt',...
    'ovation-development');

ctx = Ovation.connect(connection_file, username, password);
project = ctx.insertProject('TestImportMapping',...
    'TestImportMapping',...
    datetime());

expt = project.insertExperiment('TestImportMapping',...
    datetime());
source = ctx.insertSource('animal');

% N.B. these values should match in TestPDSImport
trialFunctionName = 'trial_function_name';
timezone = 'America/New_York';



% Import the PDS file
epochGroup = ImportPladpsPDS(expt,...
    source,...
    pdsFile,...
    trialFunctionName,...
    timezone,...
    2); %TODO only import 2 trials for now

runtests