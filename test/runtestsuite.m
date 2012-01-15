% This script builds a new Ovation database for testing and imports the
% test fixture. Run this script from the pladps-importer/test directory.
%
% After running runtestsuite, you may run runtests (the Matlab xUnit test
% runner) to re-run the test suite without building a new database or
% re-importing the test fixture data.


% N.B. these values should match in TestPldapsBase
connection_file = 'ovation/matlab_fd.connection';
username = 'TestUser';
password = 'password';

% We're tied to the test fixture defined by these files, but this is the
% only dependency. There shouldn't be any magic numbers in the test code.
pdsFile = 'fixtures/pat120811a_decision2_16.PDS';
plxFile = 'fixtures/pat120811a_decision2_1600matlabfriendlyPLX.mat';
plxRawFile = 'fixtures/pat120811a_decision2_1600.plx';
plxExpFile = 'fixtures/pat120811a_decision2_1600plx.exp';
 
% Delete the test database if it exists
if(exist(connection_file, 'file') ~= 0)
    ovation.util.deleteLocalOvationDatabase(connection_file);
end

% Create a test database
system('mkdir -p ovation');

connection_file = ovation.util.createLocalOvationDatabase('ovation', ...
    'matlab_fd',...
    username,...
    password,...
    'license.txt',...
    'ovation-development');
import ovation.*
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


warning('off', 'ovation:import:plx:unique_number');

% Import the PDS file
tic;
epochGroup = ImportPladpsPDS(expt,...
    source,...
    pdsFile,...
    trialFunctionName,...
    timezone);
    
epochGroup.addResource('edu.utexas.huk.pds', pdsFile);

tic;
ImportPLX(epochGroup,...
    plxFile,...
    plxRawFile,...
    plxExpFile);
toc;

runtests -xmlfile test-output.xml
