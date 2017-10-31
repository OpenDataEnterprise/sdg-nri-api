'use strict';

module.exports = (sequelize, DataTypes) => {
  var Model = sequelize.define('resource', {
    name: {
      type: DataTypes.STRING,
    },
    type: {
      type: DataTypes.STRING,
    },
    description: {
      type: DataTypes.STRING,
    },
    url: {
      type: DataTypes.STRING,
    },
    image: {
      type: DataTypes.STRING,
    },
    created: {
      type: DataTypes.DATE,
    },
    last_modified: {
      type: DataTypes.DATE,
    },
  }, {
    tableName: 'resource',
    underscored: true,
    timestamps: false,
    schema: process.env.DATABASE_SCHEMA,
  });

  Model.associate = (models) => {
  };

  return Model;
};

