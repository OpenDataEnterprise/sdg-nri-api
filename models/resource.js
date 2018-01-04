'use strict';

module.exports = (sequelize, DataTypes) => {
  var Model = sequelize.define('resource', {
    id: {
      type: DataTypes.UUID,
      default: DataTypes.UUIDV1,
      primaryKey: true
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
    }
  }, {
    tableName: 'resource',
    underscored: true,
    timestamps: true,
    schema: process.env.DATABASE_SCHEMA,
  });

  Model.associate = (models) => {
    /*Model.hasOne(models.country, {
      foreignKey: 'iso_alpha3'
    });*/
  };

  return Model;
};
