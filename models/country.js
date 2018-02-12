'use strict';

module.exports = (sequelize, DataTypes) => {
  var Model = sequelize.define('country', {
    iso_alpha3: {
      type: DataTypes.CHAR(3),
      primaryKey: true,
    },
    region_id: {
      type: DataTypes.CHAR(3),
      references: {
        model: sequelize.models.region,
        key: 'm49',
      },
    },
    income_group: {
      type: DataTypes.TEXT,
    },
    name: {
      type: DataTypes.TEXT,
    },
  }, {
    tableName: 'country',
    underscored: true,
    timestamps: false,
    schema: process.env.DATABASE_SCHEMA,
  });
  console.log(Model);

  Model.associate = (models) => {
    Model.belongsTo(models.region, {
      foreignKey: 'region_id',
    });
  };

  return Model;
};
