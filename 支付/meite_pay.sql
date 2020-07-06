/*
Navicat MySQL Data Transfer

Source Server         : localhost
Source Server Version : 50556
Source Host           : localhost:3306
Source Database       : meite_pay

Target Server Type    : MYSQL
Target Server Version : 50556
File Encoding         : 65001

Date: 2019-03-21 20:01:58
*/

SET FOREIGN_KEY_CHECKS=0;

-- ----------------------------
-- Table structure for payment_channel
-- ----------------------------
DROP TABLE IF EXISTS `payment_channel`;
CREATE TABLE `payment_channel` (
  `ID` int(11) NOT NULL AUTO_INCREMENT COMMENT 'ID',
  `CHANNEL_NAME` varchar(32) NOT NULL COMMENT '渠道名称',
  `CHANNEL_ID` varchar(32) NOT NULL COMMENT '渠道ID',
  `MERCHANT_ID` varchar(32) NOT NULL COMMENT '商户id',
  `SYNC_URL` text NOT NULL COMMENT '同步回调URL',
  `ASYN_URL` text NOT NULL COMMENT '异步回调URL',
  `PUBLIC_KEY` text COMMENT '公钥',
  `PRIVATE_KEY` text COMMENT '私钥',
  `CHANNEL_STATE` int(11) DEFAULT '0' COMMENT '渠道状态 0开启1关闭',
  `REVISION` int(11) DEFAULT NULL COMMENT '乐观锁',
  `CREATED_BY` varchar(32) DEFAULT NULL COMMENT '创建人',
  `CREATED_TIME` datetime DEFAULT NULL COMMENT '创建时间',
  `UPDATED_BY` varchar(32) DEFAULT NULL COMMENT '更新人',
  `UPDATED_TIME` datetime DEFAULT NULL COMMENT '更新时间',
  PRIMARY KEY (`ID`,`CHANNEL_ID`)
) ENGINE=InnoDB AUTO_INCREMENT=2 DEFAULT CHARSET=utf8 COMMENT='支付渠道 ';

-- ----------------------------
-- Records of payment_channel
-- ----------------------------
INSERT INTO `payment_channel` VALUES ('1', '银联支付', 'yinlian_pay', '777290058110048', 'http://localhost:8080/ACPSample_B2C/frontRcvResponse', 'http://222.222.222.222:8080/ACPSample_B2C/backRcvResponse', null, null, '0', null, null, null, null, null);

-- ----------------------------
-- Table structure for payment_transaction
-- ----------------------------
DROP TABLE IF EXISTS `payment_transaction`;
CREATE TABLE `payment_transaction` (
  `ID` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `PAY_AMOUNT` int(11) NOT NULL COMMENT '支付金额',
  `PAYMENT_STATUS` int(11) NOT NULL DEFAULT '0' COMMENT '支付状态 0待支付1已经支付2支付超时3支付失败',
  `USER_ID` int(11) NOT NULL COMMENT '用户ID',
  `ORDER_ID` varchar(32) NOT NULL COMMENT '订单号码',
  `REVISION` int(11) DEFAULT NULL COMMENT '乐观锁',
  `CREATED_BY` varchar(32) DEFAULT NULL COMMENT '创建人',
  `CREATED_TIME` datetime DEFAULT NULL COMMENT '创建时间',
  `UPDATED_BY` varchar(32) DEFAULT NULL COMMENT '更新人',
  `UPDATED_TIME` datetime DEFAULT NULL COMMENT '更新时间',
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB AUTO_INCREMENT=4 DEFAULT CHARSET=utf8 COMMENT='支付交易 ';

-- ----------------------------
-- Records of payment_transaction
-- ----------------------------
INSERT INTO `payment_transaction` VALUES ('1', '1000', '0', '1', '20180302101452', null, null, null, null, null);
INSERT INTO `payment_transaction` VALUES ('2', '1000', '0', '1', '20180302101452', null, null, '2019-03-21 19:06:15', null, '2019-03-21 19:06:15');
INSERT INTO `payment_transaction` VALUES ('3', '1000', '0', '1', '1', null, null, '2019-03-21 19:31:42', null, '2019-03-21 19:31:42');

-- ----------------------------
-- Table structure for payment_transaction_log
-- ----------------------------
DROP TABLE IF EXISTS `payment_transaction_log`;
CREATE TABLE `payment_transaction_log` (
  `ID` int(11) NOT NULL AUTO_INCREMENT COMMENT '主键ID',
  `SYNCH_LOG` text COMMENT '同步回调日志',
  `ASYNC_LOG` text COMMENT '异步回调日志',
  `CHANNEL_ID` int(11) DEFAULT NULL COMMENT '支付渠道ID',
  `TRANSACTION_ID` int(11) DEFAULT NULL COMMENT '支付交易ID',
  `REVISION` int(11) DEFAULT NULL COMMENT '乐观锁',
  `CREATED_BY` varchar(32) DEFAULT NULL COMMENT '创建人',
  `CREATED_TIME` datetime DEFAULT NULL COMMENT '创建时间',
  `UPDATED_BY` varchar(32) DEFAULT NULL COMMENT '更新人',
  `UPDATED_TIME` datetime DEFAULT NULL COMMENT '更新时间',
  `untitled` varchar(32) DEFAULT NULL,
  PRIMARY KEY (`ID`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8 COMMENT='支付交易日志表 ';

-- ----------------------------
-- Records of payment_transaction_log
-- ----------------------------
