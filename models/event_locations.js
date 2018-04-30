'use strict';

module.exports = (sequelize, DataTypes) => {
  var Model = sequelize.define('event_locations', {
    event_id: {
      type: DataTypes.UUID,
      primaryKey: true,
      references: {
        model: sequelize.models.event,
        key: 'uuid',
      },
    },
    location_id: {
      type: DataTypes.UUID,
      primaryKey: true,
      references: {
        model: sequelize.models.location,
        key: 'uuid',
      },
    },
  }, {
    tableName: 'event_locations',
    underscored: true,
    timestamps: false,
    schema: process.env.DATABASE_SCHEMA,
  });

  Model.associate = (models) => {
    Model.belongsTo(models.event, {
      foreignKey: 'event_id',
    });
    Model.belongsTo(models.location, {
      foreignKey: 'location_id',
    });
  };

  return Model;
};
