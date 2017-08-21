-- MySQL dump 10.13  Distrib 5.7.19, for Linux (x86_64)
--
-- Host: localhost    Database: gha
-- ------------------------------------------------------
-- Server version	5.7.19-0ubuntu0.17.04.1

/*!40101 SET @OLD_CHARACTER_SET_CLIENT=@@CHARACTER_SET_CLIENT */;
/*!40101 SET @OLD_CHARACTER_SET_RESULTS=@@CHARACTER_SET_RESULTS */;
/*!40101 SET @OLD_COLLATION_CONNECTION=@@COLLATION_CONNECTION */;
/*!40101 SET NAMES utf8mb4 */;
/*!40103 SET @OLD_TIME_ZONE=@@TIME_ZONE */;
/*!40103 SET TIME_ZONE='+00:00' */;
/*!40014 SET @OLD_UNIQUE_CHECKS=@@UNIQUE_CHECKS, UNIQUE_CHECKS=0 */;
/*!40014 SET @OLD_FOREIGN_KEY_CHECKS=@@FOREIGN_KEY_CHECKS, FOREIGN_KEY_CHECKS=0 */;
/*!40101 SET @OLD_SQL_MODE=@@SQL_MODE, SQL_MODE='NO_AUTO_VALUE_ON_ZERO' */;
/*!40111 SET @OLD_SQL_NOTES=@@SQL_NOTES, SQL_NOTES=0 */;

--
-- Table structure for table `gha_actors`
--

DROP TABLE IF EXISTS `gha_actors`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `gha_actors` (
  `id` bigint(20) NOT NULL,
  `login` varchar(120) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id`),
  KEY `actors_login_idx` (`login`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `gha_actors`
--

LOCK TABLES `gha_actors` WRITE;
/*!40000 ALTER TABLE `gha_actors` DISABLE KEYS */;
/*!40000 ALTER TABLE `gha_actors` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `gha_assets`
--

DROP TABLE IF EXISTS `gha_assets`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `gha_assets` (
  `id` bigint(20) NOT NULL,
  `event_id` bigint(20) NOT NULL,
  `name` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
  `label` varchar(120) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `uploader_id` bigint(20) NOT NULL,
  `content_type` varchar(80) COLLATE utf8mb4_unicode_ci NOT NULL,
  `state` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `size` int(11) NOT NULL,
  `download_count` int(11) NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`,`event_id`),
  KEY `assets_event_id_idx` (`event_id`),
  KEY `assets_uploader_id_idx` (`uploader_id`),
  KEY `assets_content_type_idx` (`content_type`),
  KEY `assets_state_idx` (`state`),
  KEY `assets_created_at_idx` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `gha_assets`
--

LOCK TABLES `gha_assets` WRITE;
/*!40000 ALTER TABLE `gha_assets` DISABLE KEYS */;
/*!40000 ALTER TABLE `gha_assets` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `gha_branches`
--

DROP TABLE IF EXISTS `gha_branches`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `gha_branches` (
  `sha` varchar(40) COLLATE utf8mb4_unicode_ci NOT NULL,
  `event_id` bigint(20) NOT NULL,
  `user_id` bigint(20) DEFAULT NULL,
  `repo_id` bigint(20) DEFAULT NULL,
  `label` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
  `ref` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`sha`,`event_id`),
  KEY `branches_event_id_idx` (`event_id`),
  KEY `branches_user_id_idx` (`user_id`),
  KEY `branches_repo_id_idx` (`repo_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `gha_branches`
--

LOCK TABLES `gha_branches` WRITE;
/*!40000 ALTER TABLE `gha_branches` DISABLE KEYS */;
/*!40000 ALTER TABLE `gha_branches` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `gha_comments`
--

DROP TABLE IF EXISTS `gha_comments`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `gha_comments` (
  `id` bigint(20) NOT NULL,
  `event_id` bigint(20) NOT NULL,
  `body` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `type` varchar(40) COLLATE utf8mb4_unicode_ci NOT NULL,
  `user_id` bigint(20) NOT NULL,
  `commit_id` varchar(40) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `original_commit_id` varchar(40) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `diff_hunk` text COLLATE utf8mb4_unicode_ci,
  `position` int(11) DEFAULT NULL,
  `original_position` int(11) DEFAULT NULL,
  `path` text COLLATE utf8mb4_unicode_ci,
  `pull_request_review_id` bigint(20) DEFAULT NULL,
  `line` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `comments_event_id_idx` (`event_id`),
  KEY `comments_type_idx` (`type`),
  KEY `comments_created_at_idx` (`created_at`),
  KEY `comments_user_id_idx` (`user_id`),
  KEY `comments_commit_id_idx` (`commit_id`),
  KEY `comments_pull_request_review_id_idx` (`pull_request_review_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `gha_comments`
--

LOCK TABLES `gha_comments` WRITE;
/*!40000 ALTER TABLE `gha_comments` DISABLE KEYS */;
/*!40000 ALTER TABLE `gha_comments` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `gha_commits`
--

DROP TABLE IF EXISTS `gha_commits`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `gha_commits` (
  `sha` varchar(40) COLLATE utf8mb4_unicode_ci NOT NULL,
  `event_id` bigint(20) NOT NULL,
  `author_name` varchar(160) COLLATE utf8mb4_unicode_ci NOT NULL,
  `message` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `is_distinct` tinyint(1) NOT NULL,
  PRIMARY KEY (`sha`,`event_id`),
  KEY `commits_event_id_idx` (`event_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `gha_commits`
--

LOCK TABLES `gha_commits` WRITE;
/*!40000 ALTER TABLE `gha_commits` DISABLE KEYS */;
/*!40000 ALTER TABLE `gha_commits` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `gha_events`
--

DROP TABLE IF EXISTS `gha_events`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `gha_events` (
  `id` bigint(20) NOT NULL,
  `type` varchar(40) COLLATE utf8mb4_unicode_ci NOT NULL,
  `actor_id` bigint(20) NOT NULL,
  `repo_id` bigint(20) NOT NULL,
  `public` tinyint(1) NOT NULL,
  `created_at` datetime NOT NULL,
  `org_id` bigint(20) DEFAULT NULL,
  `actor_login` varchar(120) COLLATE utf8mb4_unicode_ci NOT NULL,
  `repo_name` varchar(160) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id`),
  KEY `events_type_idx` (`type`),
  KEY `events_actor_id_idx` (`actor_id`),
  KEY `events_repo_id_idx` (`repo_id`),
  KEY `events_org_id_idx` (`org_id`),
  KEY `events_created_at_idx` (`created_at`),
  KEY `events_actor_login_idx` (`actor_login`),
  KEY `events_repo_name_idx` (`repo_name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `gha_events`
--

LOCK TABLES `gha_events` WRITE;
/*!40000 ALTER TABLE `gha_events` DISABLE KEYS */;
/*!40000 ALTER TABLE `gha_events` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `gha_events_commits`
--

DROP TABLE IF EXISTS `gha_events_commits`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `gha_events_commits` (
  `event_id` bigint(20) NOT NULL,
  `sha` varchar(40) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`event_id`,`sha`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `gha_events_commits`
--

LOCK TABLES `gha_events_commits` WRITE;
/*!40000 ALTER TABLE `gha_events_commits` DISABLE KEYS */;
/*!40000 ALTER TABLE `gha_events_commits` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `gha_events_pages`
--

DROP TABLE IF EXISTS `gha_events_pages`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `gha_events_pages` (
  `event_id` bigint(20) NOT NULL,
  `sha` varchar(40) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`event_id`,`sha`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `gha_events_pages`
--

LOCK TABLES `gha_events_pages` WRITE;
/*!40000 ALTER TABLE `gha_events_pages` DISABLE KEYS */;
/*!40000 ALTER TABLE `gha_events_pages` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `gha_forkees`
--

DROP TABLE IF EXISTS `gha_forkees`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `gha_forkees` (
  `id` bigint(20) NOT NULL,
  `event_id` bigint(20) NOT NULL,
  `name` varchar(80) COLLATE utf8mb4_unicode_ci NOT NULL,
  `full_name` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
  `owner_id` bigint(20) NOT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `fork` tinyint(1) NOT NULL,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `pushed_at` datetime NOT NULL,
  `homepage` text COLLATE utf8mb4_unicode_ci,
  `size` int(11) NOT NULL,
  `stargazers_count` int(11) NOT NULL,
  `has_issues` tinyint(1) NOT NULL,
  `has_projects` tinyint(1) DEFAULT NULL,
  `has_downloads` tinyint(1) NOT NULL,
  `has_wiki` tinyint(1) NOT NULL,
  `has_pages` tinyint(1) DEFAULT NULL,
  `forks` int(11) NOT NULL,
  `open_issues` int(11) NOT NULL,
  `watchers` int(11) NOT NULL,
  `default_branch` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
  `public` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`id`,`event_id`),
  KEY `forkees_event_id_idx` (`event_id`),
  KEY `forkees_owner_id_idx` (`owner_id`),
  KEY `forkees_created_at_idx` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `gha_forkees`
--

LOCK TABLES `gha_forkees` WRITE;
/*!40000 ALTER TABLE `gha_forkees` DISABLE KEYS */;
/*!40000 ALTER TABLE `gha_forkees` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `gha_issues`
--

DROP TABLE IF EXISTS `gha_issues`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `gha_issues` (
  `id` bigint(20) NOT NULL,
  `event_id` bigint(20) NOT NULL,
  `assignee_id` bigint(20) DEFAULT NULL,
  `body` text COLLATE utf8mb4_unicode_ci,
  `closed_at` datetime DEFAULT NULL,
  `comments` int(11) NOT NULL,
  `created_at` datetime NOT NULL,
  `locked` tinyint(1) NOT NULL,
  `milestone_id` bigint(20) DEFAULT NULL,
  `number` int(11) NOT NULL,
  `state` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `title` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `updated_at` datetime NOT NULL,
  `user_id` bigint(20) NOT NULL,
  `is_pull_request` tinyint(1) NOT NULL,
  PRIMARY KEY (`id`,`event_id`),
  KEY `issues_event_id_idx` (`event_id`),
  KEY `issues_assignee_id_idx` (`assignee_id`),
  KEY `issues_created_at_idx` (`created_at`),
  KEY `issues_closed_at_idx` (`closed_at`),
  KEY `issues_milestone_id_idx` (`milestone_id`),
  KEY `issues_state_idx` (`state`),
  KEY `issues_user_id_idx` (`user_id`),
  KEY `issues_is_pull_request_idx` (`is_pull_request`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `gha_issues`
--

LOCK TABLES `gha_issues` WRITE;
/*!40000 ALTER TABLE `gha_issues` DISABLE KEYS */;
/*!40000 ALTER TABLE `gha_issues` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `gha_issues_assignees`
--

DROP TABLE IF EXISTS `gha_issues_assignees`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `gha_issues_assignees` (
  `issue_id` bigint(20) NOT NULL,
  `event_id` bigint(20) NOT NULL,
  `assignee_id` bigint(20) NOT NULL,
  PRIMARY KEY (`issue_id`,`event_id`,`assignee_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `gha_issues_assignees`
--

LOCK TABLES `gha_issues_assignees` WRITE;
/*!40000 ALTER TABLE `gha_issues_assignees` DISABLE KEYS */;
/*!40000 ALTER TABLE `gha_issues_assignees` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `gha_issues_events_labels`
--

DROP TABLE IF EXISTS `gha_issues_events_labels`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `gha_issues_events_labels` (
  `issue_id` bigint(20) NOT NULL,
  `event_id` bigint(20) NOT NULL,
  `label_id` bigint(20) NOT NULL,
  `label_name` varchar(160) COLLATE utf8mb4_unicode_ci NOT NULL,
  `created_at` datetime NOT NULL,
  KEY `issues_events_labels_issue_id_idx` (`issue_id`),
  KEY `issues_events_labels_event_id_idx` (`event_id`),
  KEY `issues_events_labels_label_id_idx` (`label_id`),
  KEY `issues_events_labels_label_name_idx` (`label_name`),
  KEY `issues_events_labels_created_at_idx` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `gha_issues_events_labels`
--

LOCK TABLES `gha_issues_events_labels` WRITE;
/*!40000 ALTER TABLE `gha_issues_events_labels` DISABLE KEYS */;
/*!40000 ALTER TABLE `gha_issues_events_labels` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `gha_issues_labels`
--

DROP TABLE IF EXISTS `gha_issues_labels`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `gha_issues_labels` (
  `issue_id` bigint(20) NOT NULL,
  `event_id` bigint(20) NOT NULL,
  `label_id` bigint(20) NOT NULL,
  PRIMARY KEY (`issue_id`,`event_id`,`label_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `gha_issues_labels`
--

LOCK TABLES `gha_issues_labels` WRITE;
/*!40000 ALTER TABLE `gha_issues_labels` DISABLE KEYS */;
/*!40000 ALTER TABLE `gha_issues_labels` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `gha_labels`
--

DROP TABLE IF EXISTS `gha_labels`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `gha_labels` (
  `id` bigint(20) NOT NULL,
  `name` varchar(160) COLLATE utf8mb4_unicode_ci NOT NULL,
  `color` varchar(8) COLLATE utf8mb4_unicode_ci NOT NULL,
  `is_default` tinyint(1) DEFAULT NULL,
  PRIMARY KEY (`id`),
  KEY `labels_name_idx` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `gha_labels`
--

LOCK TABLES `gha_labels` WRITE;
/*!40000 ALTER TABLE `gha_labels` DISABLE KEYS */;
/*!40000 ALTER TABLE `gha_labels` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `gha_milestones`
--

DROP TABLE IF EXISTS `gha_milestones`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `gha_milestones` (
  `id` bigint(20) NOT NULL,
  `event_id` bigint(20) NOT NULL,
  `closed_at` datetime DEFAULT NULL,
  `closed_issues` int(11) NOT NULL,
  `created_at` datetime NOT NULL,
  `creator_id` bigint(20) DEFAULT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `due_on` datetime DEFAULT NULL,
  `number` int(11) NOT NULL,
  `open_issues` int(11) NOT NULL,
  `state` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `title` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
  `updated_at` datetime NOT NULL,
  PRIMARY KEY (`id`,`event_id`),
  KEY `milestones_event_id_idx` (`event_id`),
  KEY `milestones_created_at_idx` (`created_at`),
  KEY `milestones_creator_id_idx` (`creator_id`),
  KEY `milestones_state_idx` (`state`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `gha_milestones`
--

LOCK TABLES `gha_milestones` WRITE;
/*!40000 ALTER TABLE `gha_milestones` DISABLE KEYS */;
/*!40000 ALTER TABLE `gha_milestones` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `gha_orgs`
--

DROP TABLE IF EXISTS `gha_orgs`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `gha_orgs` (
  `id` bigint(20) NOT NULL,
  `login` varchar(100) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id`),
  KEY `orgs_login_idx` (`login`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `gha_orgs`
--

LOCK TABLES `gha_orgs` WRITE;
/*!40000 ALTER TABLE `gha_orgs` DISABLE KEYS */;
/*!40000 ALTER TABLE `gha_orgs` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `gha_pages`
--

DROP TABLE IF EXISTS `gha_pages`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `gha_pages` (
  `sha` varchar(40) COLLATE utf8mb4_unicode_ci NOT NULL,
  `event_id` bigint(20) NOT NULL,
  `action` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `title` varchar(300) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`sha`,`event_id`,`action`,`title`),
  KEY `pages_event_id_idx` (`event_id`),
  KEY `pages_action_idx` (`action`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `gha_pages`
--

LOCK TABLES `gha_pages` WRITE;
/*!40000 ALTER TABLE `gha_pages` DISABLE KEYS */;
/*!40000 ALTER TABLE `gha_pages` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `gha_payloads`
--

DROP TABLE IF EXISTS `gha_payloads`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `gha_payloads` (
  `event_id` bigint(20) NOT NULL,
  `push_id` int(11) DEFAULT NULL,
  `size` int(11) DEFAULT NULL,
  `ref` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `head` varchar(40) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `befor` varchar(40) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `action` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `issue_id` bigint(20) DEFAULT NULL,
  `comment_id` bigint(20) DEFAULT NULL,
  `ref_type` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `master_branch` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `description` text COLLATE utf8mb4_unicode_ci,
  `number` int(11) DEFAULT NULL,
  `forkee_id` bigint(20) DEFAULT NULL,
  `release_id` bigint(20) DEFAULT NULL,
  `member_id` bigint(20) DEFAULT NULL,
  PRIMARY KEY (`event_id`),
  KEY `payloads_action_idx` (`action`),
  KEY `payloads_head_idx` (`head`),
  KEY `payloads_issue_id_idx` (`issue_id`),
  KEY `payloads_comment_id_idx` (`comment_id`),
  KEY `payloads_ref_type_idx` (`ref_type`),
  KEY `payloads_forkee_id_idx` (`forkee_id`),
  KEY `payloads_release_id_idx` (`release_id`),
  KEY `payloads_member_id_idx` (`member_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `gha_payloads`
--

LOCK TABLES `gha_payloads` WRITE;
/*!40000 ALTER TABLE `gha_payloads` DISABLE KEYS */;
/*!40000 ALTER TABLE `gha_payloads` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `gha_pull_requests`
--

DROP TABLE IF EXISTS `gha_pull_requests`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `gha_pull_requests` (
  `id` bigint(20) NOT NULL,
  `event_id` bigint(20) NOT NULL,
  `user_id` bigint(20) NOT NULL,
  `base_sha` varchar(40) COLLATE utf8mb4_unicode_ci NOT NULL,
  `head_sha` varchar(40) COLLATE utf8mb4_unicode_ci NOT NULL,
  `merged_by_id` bigint(20) DEFAULT NULL,
  `assignee_id` bigint(20) DEFAULT NULL,
  `milestone_id` bigint(20) DEFAULT NULL,
  `number` int(11) NOT NULL,
  `state` varchar(20) COLLATE utf8mb4_unicode_ci NOT NULL,
  `locked` tinyint(1) NOT NULL,
  `title` text COLLATE utf8mb4_unicode_ci NOT NULL,
  `body` text COLLATE utf8mb4_unicode_ci,
  `created_at` datetime NOT NULL,
  `updated_at` datetime NOT NULL,
  `closed_at` datetime DEFAULT NULL,
  `merged_at` datetime DEFAULT NULL,
  `merge_commit_sha` varchar(40) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `merged` tinyint(1) DEFAULT NULL,
  `mergeable` tinyint(1) DEFAULT NULL,
  `rebaseable` tinyint(1) DEFAULT NULL,
  `mergeable_state` varchar(20) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `comments` int(11) DEFAULT NULL,
  `review_comments` int(11) DEFAULT NULL,
  `maintainer_can_modify` tinyint(1) DEFAULT NULL,
  `commits` int(11) DEFAULT NULL,
  `additions` int(11) DEFAULT NULL,
  `deletions` int(11) DEFAULT NULL,
  `changed_files` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`,`event_id`),
  KEY `pull_requests_event_id_idx` (`event_id`),
  KEY `pull_requests_user_id_idx` (`user_id`),
  KEY `pull_requests_base_sha_idx` (`base_sha`),
  KEY `pull_requests_head_sha_idx` (`head_sha`),
  KEY `pull_requests_merged_by_id_idx` (`merged_by_id`),
  KEY `pull_requests_assignee_id_idx` (`assignee_id`),
  KEY `pull_requests_milestone_id_idx` (`milestone_id`),
  KEY `pull_requests_state_idx` (`state`),
  KEY `pull_requests_created_at_idx` (`created_at`),
  KEY `pull_requests_closed_at_idx` (`closed_at`),
  KEY `pull_requests_merged_at_idx` (`merged_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `gha_pull_requests`
--

LOCK TABLES `gha_pull_requests` WRITE;
/*!40000 ALTER TABLE `gha_pull_requests` DISABLE KEYS */;
/*!40000 ALTER TABLE `gha_pull_requests` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `gha_pull_requests_assignees`
--

DROP TABLE IF EXISTS `gha_pull_requests_assignees`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `gha_pull_requests_assignees` (
  `pull_request_id` bigint(20) NOT NULL,
  `event_id` bigint(20) NOT NULL,
  `assignee_id` bigint(20) NOT NULL,
  PRIMARY KEY (`pull_request_id`,`event_id`,`assignee_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `gha_pull_requests_assignees`
--

LOCK TABLES `gha_pull_requests_assignees` WRITE;
/*!40000 ALTER TABLE `gha_pull_requests_assignees` DISABLE KEYS */;
/*!40000 ALTER TABLE `gha_pull_requests_assignees` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `gha_pull_requests_requested_reviewers`
--

DROP TABLE IF EXISTS `gha_pull_requests_requested_reviewers`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `gha_pull_requests_requested_reviewers` (
  `pull_request_id` bigint(20) NOT NULL,
  `event_id` bigint(20) NOT NULL,
  `requested_reviewer_id` bigint(20) NOT NULL,
  PRIMARY KEY (`pull_request_id`,`event_id`,`requested_reviewer_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `gha_pull_requests_requested_reviewers`
--

LOCK TABLES `gha_pull_requests_requested_reviewers` WRITE;
/*!40000 ALTER TABLE `gha_pull_requests_requested_reviewers` DISABLE KEYS */;
/*!40000 ALTER TABLE `gha_pull_requests_requested_reviewers` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `gha_releases`
--

DROP TABLE IF EXISTS `gha_releases`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `gha_releases` (
  `id` bigint(20) NOT NULL,
  `event_id` bigint(20) NOT NULL,
  `tag_name` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
  `target_commitish` varchar(200) COLLATE utf8mb4_unicode_ci NOT NULL,
  `name` varchar(200) COLLATE utf8mb4_unicode_ci DEFAULT NULL,
  `draft` tinyint(1) NOT NULL,
  `author_id` bigint(20) NOT NULL,
  `prerelease` tinyint(1) NOT NULL,
  `created_at` datetime NOT NULL,
  `published_at` datetime NOT NULL,
  `body` text COLLATE utf8mb4_unicode_ci,
  PRIMARY KEY (`id`,`event_id`),
  KEY `releases_event_id_idx` (`event_id`),
  KEY `releases_author_id_idx` (`author_id`),
  KEY `releases_created_at_idx` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `gha_releases`
--

LOCK TABLES `gha_releases` WRITE;
/*!40000 ALTER TABLE `gha_releases` DISABLE KEYS */;
/*!40000 ALTER TABLE `gha_releases` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `gha_releases_assets`
--

DROP TABLE IF EXISTS `gha_releases_assets`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `gha_releases_assets` (
  `release_id` bigint(20) NOT NULL,
  `event_id` bigint(20) NOT NULL,
  `asset_id` bigint(20) NOT NULL,
  PRIMARY KEY (`release_id`,`event_id`,`asset_id`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `gha_releases_assets`
--

LOCK TABLES `gha_releases_assets` WRITE;
/*!40000 ALTER TABLE `gha_releases_assets` DISABLE KEYS */;
/*!40000 ALTER TABLE `gha_releases_assets` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `gha_repos`
--

DROP TABLE IF EXISTS `gha_repos`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `gha_repos` (
  `id` bigint(20) NOT NULL,
  `name` varchar(160) COLLATE utf8mb4_unicode_ci NOT NULL,
  PRIMARY KEY (`id`),
  KEY `repos_name_idx` (`name`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `gha_repos`
--

LOCK TABLES `gha_repos` WRITE;
/*!40000 ALTER TABLE `gha_repos` DISABLE KEYS */;
/*!40000 ALTER TABLE `gha_repos` ENABLE KEYS */;
UNLOCK TABLES;

--
-- Table structure for table `gha_texts`
--

DROP TABLE IF EXISTS `gha_texts`;
/*!40101 SET @saved_cs_client     = @@character_set_client */;
/*!40101 SET character_set_client = utf8 */;
CREATE TABLE `gha_texts` (
  `event_id` bigint(20) DEFAULT NULL,
  `body` text COLLATE utf8mb4_unicode_ci,
  `created_at` datetime NOT NULL,
  KEY `texts_event_id_idx` (`event_id`),
  KEY `texts_created_at_idx` (`created_at`)
) ENGINE=InnoDB DEFAULT CHARSET=utf8mb4 COLLATE=utf8mb4_unicode_ci;
/*!40101 SET character_set_client = @saved_cs_client */;

--
-- Dumping data for table `gha_texts`
--

LOCK TABLES `gha_texts` WRITE;
/*!40000 ALTER TABLE `gha_texts` DISABLE KEYS */;
/*!40000 ALTER TABLE `gha_texts` ENABLE KEYS */;
UNLOCK TABLES;
/*!40103 SET TIME_ZONE=@OLD_TIME_ZONE */;

/*!40101 SET SQL_MODE=@OLD_SQL_MODE */;
/*!40014 SET FOREIGN_KEY_CHECKS=@OLD_FOREIGN_KEY_CHECKS */;
/*!40014 SET UNIQUE_CHECKS=@OLD_UNIQUE_CHECKS */;
/*!40101 SET CHARACTER_SET_CLIENT=@OLD_CHARACTER_SET_CLIENT */;
/*!40101 SET CHARACTER_SET_RESULTS=@OLD_CHARACTER_SET_RESULTS */;
/*!40101 SET COLLATION_CONNECTION=@OLD_COLLATION_CONNECTION */;
/*!40111 SET SQL_NOTES=@OLD_SQL_NOTES */;

-- Dump completed on 2017-08-21  6:50:01
