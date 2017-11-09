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
    image_url: {
      type: DataTypes.STRING,
    },
    tags: {
      type: DataTypes.ARRAY(DataTypes.STRING),
    },
    first_created: {
      type: DataTypes.DATE,
    },
    last_modified: {
      type: DataTypes.DATE,
    },
    organization: {
      type: DataTypes.STRING,
    },
    date_published: {
      type: DataTypes.DATE,
    },
    geographical_unit_id: {
      type: DataTypes.INTEGER,
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

