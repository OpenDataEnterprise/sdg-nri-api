'use strict';

module.exports = (sequelize, DataTypes) => {
  var Model = sequelize.define('country', {
    iso_alpha3: {
      type: DataTypes.CHAR(3),
      field: 'iso_alpha3',
      primaryKey: true,
    },
    region_id: {
      type: DataTypes.STRING,
      references: {
        model: sequelize.models.region,
        key: 'm49',
        deferrable: sequelize.Deferrable.INITIALLY_IMMEDIATE,
      }
    },
    income_group: {
      type: DataTypes.STRING,
    },
    name: {
      type: DataTypes.STRING,
    },
  }, {
    tableName: 'country',
    underscored: true,
    timestamps: false,
    schema: process.env.DATABASE_SCHEMA,
  });

  Model.associate = (models) => {
    Model.belongsTo(models.region, {
      foreignKey: 'region_id',
    });
  };

  return Model;
};

