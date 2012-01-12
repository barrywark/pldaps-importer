% N.B. these values should match in TestPldapsBase
connection_file = 'ovation/matlab_fd.connection';
username = 'TestUser';
password = 'password';

% We're tied to the test fixture defined by these files, but this is the
% only dependency. There shouldn't be any magic numbers in the test code.
pdsFile = 'fixtures/pat120811a_decision2_16.PDS';
plxFile = 'fixtures/pat120811a_decision2_1600matlabfriendlyPLX.mat';
plxExpFile = 'fixtures/pat120811a_decision2_1600plx.exp';
 
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
    25); %TODO only import 2 trials for now

ImportPLX(epochGroup, plxFile, plxExpFile, expt.externalDevice('TODO','TODO'));

runtests