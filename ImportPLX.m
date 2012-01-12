function ImportPLX(context, plexus_device, plxfile)
    load('-mat', plxfile)

    context.query('Epoch', 'properties');
end