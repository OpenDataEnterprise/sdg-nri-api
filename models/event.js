'use strict';

module.exports = (sequelize, DataTypes) => {
  var Model = sequelize.define('event', {
    uuid: {
      type: DataTypes.UUID,
      defaultValue: sequelize.literal('uuid_generate_v1mc()'),
      primaryKey: true,
    },
    title: {
      type: DataTypes.TEXT,
    },
    url: {
      type: DataTypes.TEXT,
    },
    description: {
      type: DataTypes.TEXT,
    },
    start_time: {
      type: DataTypes.DATE,
    },
    end_time: {
      type: DataTypes.DATE,
    },
    locations: {
      type: DataTypes.ARRAY(DataTypes.TEXT),
    },
    tags: {
      type: DataTypes.ARRAY(DataTypes.TEXT),
    },
  }, {
    tableName: 'event',
    underscored: true,
    timestamps: true,
    schema: process.env.DATABASE_SCHEMA,
  });

  return Model;
};

