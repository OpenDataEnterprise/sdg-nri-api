'use strict';

module.exports = (sequelize, DataTypes) => {
  var Model = sequelize.define('resource', {
    uuid: {
      type: DataTypes.UUID,
    },
    country_id: {
      type: DataTypes.STRING,
    },
    title: {
      type: DataTypes.STRING,
    },
    organization: {
      type: DataTypes.STRING,
    },
    url: {
      type: DataTypes.STRING,
    },
    date_published: {
      type: DataTypes.DATE,
    },
    image_url: {
      type: DataTypes.STRING,
    },
    description: {
      type: DataTypes.STRING,
    },
    type: {
      type: DataTypes.STRING,
    },
    tags: {
      type: DataTypes.ARRAY(DataTypes.STRING),
    },
    publish: {
      type: DataTypes.BOOLEAN,
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
      Model.hasOne(model.country, {
        foreignKey: 'iso_alpha3',
      });
  };

  return Model;
};

