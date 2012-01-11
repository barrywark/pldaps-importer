=============================
PL-DA-PS importer for Ovation
=============================


This project contains Matlab[1]_ code for importing `PL-DA-PS <http://hukdata.cps.utexas.edu/archive/PLDAPS.html>` data into the `Ovation Scientific Data Management System <http://physionconsulting.com/web/Ovation.html>`.

Basic Usage
-----------

To use the importer:

#. add the project directory to the Matlab path
#. Choose an Ovation ``Experiment`` object to insert data into. To create a ``Project`` and ``Experiment``::

    >> import ovation.*
    >> context = NewDataContext(<path_to_connection_file>, <username>);
    >> project = context.insertProject(<project name>, <project purpose>, <project start date>);
    >> experiment = project.insertExperiment(<expt purpose>, <expt start date>);
#. Insert a PL-DA-PS ``.PDS`` file as an ``EpochGroup``::

    >> epochGropu = ImportPladpsPDS(experiment,...
        <path to PDS file>,...
        trialFunctionName,...
        experimentTimeZone)
        

#. Export spike sorting data from a ``.plx`` to a Matlab ``.mat`` file::
    
    >> plx2mat ??
    
#. Append ``DerivedResponses`` with spike times and spike waveforms to ``Epochs`` already in the database::

    >> ImportPladpsPlx(epochGroup,...
        <path to Matlab plx data>);

.. Note:: This step will fail if ``Epochs`` in the plexon data are not already represented by ``Epoch`` instances in the Ovaiton database.



.. [1] Matlab is a registered trademark of The Mathworks, Inc..


