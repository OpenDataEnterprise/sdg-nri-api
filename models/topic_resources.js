'use strict';

module.exports = (sequelize, DataTypes) => {
  var Model = sequelize.define('topic_resources', {
    topic_id: {
      type: DataTypes.INTEGER,
    },
    resource_id: {
      type: DataTypes.INTEGER,
    },
  }, {
    tableName: 'topic_resources',
    underscored: true,
    timestamps: false,
    schema: process.env.DATABASE_SCHEMA,
  });

  Model.associate = (models) => {
  };

  return Model;
};

