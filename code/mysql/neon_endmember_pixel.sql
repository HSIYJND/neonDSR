CREATE DATABASE  IF NOT EXISTS `neon` /*!40100 DEFAULT CHARACTER SET latin1 */;
USE `neon`;
-- MySQL dump 10.13  Distrib 5.5.35, for debian-linux-gnu (i686)
--
-- Host: 127.0.0.1    Database: neon
-- ------------------------------------------------------
-- Server version	5.5.35-0ubuntu0.12.04.2

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `endmember_pixel`
--

DROP TABLE IF EXISTS `endmember_pixel`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `endmember_pixel` (
  `pixel_id` int(11) NOT NULL,
  `endmember_id` int(11) NOT NULL,
  `probability` float NOT NULL,
  KEY `fk_pixel_id` (`pixel_id`),
  KEY `fk_endmember` (`endmember_id`),
  CONSTRAINT `fk_endmember` FOREIGN KEY (`endmember_id`) REFERENCES `endmember` (`id`) ON DELETE CASCADE,
  CONSTRAINT `fk_pixel_id` FOREIGN KEY (`pixel_id`) REFERENCES `pixel` (`pixel_id`)
) ENGINE=InnoDB DEFAULT CHARSET=latin1;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `endmember_pixel`
--

LOCK TABLES `endmember_pixel` WRITE;
/*!40000 ALTER TABLE `endmember_pixel` DISABLE KEYS */;
INSERT INTO `endmember_pixel` VALUES (1,1,0.2),(1,1,0.3),(1,1,0.4),(1,1,0.1),(2,1,0.25),(2,1,0.75);
/*!40000 ALTER TABLE `endmember_pixel` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2014-02-18  9:04:05
