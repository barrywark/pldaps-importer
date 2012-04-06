function runtestsuite(test_directory)

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

    % We're tied to the test fixture defined by these files and values, 
    % but this is the only dependency. There shouldn't be any magic numbers
    % in the test code.
    pdsFile = TestPldapsBase.pdsFile;
    plxFile = TestPldapsBase.plxFile;
    plxRawFile = TestPldapsBase.plxRawFile;
    plxExpFile = TestPldapsBase.plxExpFile;
    timezone = TestPldapsBase.timezone;

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
    epochGroup = ImportPldapsPDS(expt,...
    source,...
    pdsFile,...
    timezone);
    toc;
    epochGroup.addResource('edu.utexas.huk.pds', pdsFile);
    
    pdsStruct = load(pdsFile, '-mat');
    dv = pdsStruct.dv;
    
    tic;
    ImportPLX(epochGroup,...
        plxFile,...
        dv.bits,...
        plxRawFile,...
        plxExpFile);
    toc;

    runtests(test_directory, '-xmlfile', 'test-output.xml');

end