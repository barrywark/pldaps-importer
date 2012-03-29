function runtestsuite(test_directory)

    % This script builds a new Ovation database for testing and imports the
    % test fixture. Run this script from the pladps-importer/test directory.
    %
    % After running runtestsuite, you may run runtests (the Matlab xUnit test
    % runner) to re-run the test suite without building a new database or
    % re-importing the test fixture data.


    import org.joda.time.*;
    
    % N.B. these values should match in TestPldapsBase
    connection_file = 'ovation/matlab_fd.connection';
    username = 'TestUser';
    password = 'password';

    % We're tied to the test fixture defined by these files and values, 
    % but this is the only dependency. There shouldn't be any magic numbers
    % in the test code.
    pdsFile = 'fixtures/ovationtest032712revcodots1440.PDS';
    plxFile = 'fixtures/ovationtest032712revcodots1441.MAT';
    plxRawFile = 'fixtures/ovationtest032712revcodots1441.plx';
    plxExpFile = 'fixtures/ovationtest032712revcodots1441.exp';
    timezone = DateTimeZone.forID('US/Central');

    % Delete the test database if it exists
    if(exist(connection_file, 'file') ~= 0)
        ovation.util.deleteLocalOvationDatabase(connection_file, true);
    end

    % Create a test database
    system('mkdir -p ovation');

    connection_file = ovation.util.createLocalOvationDatabase('ovation', ...
    'matlab_fd',...
    username,...
    password); %,...
    %'license.txt',...
    %'ovation-development');
    
    import ovation.*
    ctx = Ovation.connect(fullfile(pwd(),connection_file), username, password);
    project = ctx.insertProject('TestImportMapping',...
    'TestImportMapping',...
    datetime());

    expt = project.insertExperiment('TestImportMapping',...
    datetime());
    source = ctx.insertSource('animal');



    warning('off', 'ovation:import:plx:unique_number');

    % Import the PDS file
    tic;
    epochGroup = ImportPladpsPDS(expt,...
    source,...
    pdsFile,...
    timezone);
    toc;
    epochGroup.addResource('edu.utexas.huk.pds', pdsFile);

    tic;
    ImportPLX(epochGroup,...
    plxFile,...
    plxRawFile,...
    plxExpFile);
    toc;

    runtests(test_directory, '-xmlfile', 'test-output.xml');

end