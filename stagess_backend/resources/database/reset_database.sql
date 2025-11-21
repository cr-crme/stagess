/* USE xxx must be done prior to this script to select the correct database */

/* Clear the database */
SET FOREIGN_KEY_CHECKS = 0;

DROP TABLE IF EXISTS entities;
DROP TABLE IF EXISTS phone_numbers;
DROP TABLE IF EXISTS addresses;

DROP TABLE IF EXISTS persons;
DROP TABLE IF EXISTS admins;

DROP TABLE IF EXISTS student_contacts;
DROP TABLE IF EXISTS students;

DROP TABLE IF EXISTS teaching_groups;
DROP TABLE IF EXISTS teacher_itineraries;
DROP TABLE IF EXISTS teacher_itinerary_waypoints;
DROP TABLE IF EXISTS teachers;

DROP TABLE IF EXISTS enterprise_addresses;
DROP TABLE IF EXISTS enterprise_headquarters_addresses;
DROP TABLE IF EXISTS enterprise_phone_numbers;
DROP TABLE IF EXISTS enterprise_fax_numbers;
DROP TABLE IF EXISTS enterprise_activity_types;
DROP TABLE IF EXISTS enterprise_contacts;
DROP TABLE IF EXISTS enterprise_jobs;
DROP TABLE IF EXISTS enterprise_job_positions_offered;
DROP TABLE IF EXISTS enterprise_job_photos;
DROP TABLE IF EXISTS enterprise_job_comments;
DROP TABLE IF EXISTS enterprise_job_pre_internship_request_items;
DROP TABLE IF EXISTS enterprise_job_pre_internship_requests;
DROP TABLE IF EXISTS enterprise_job_uniforms;
DROP TABLE IF EXISTS enterprise_job_protections;
DROP TABLE IF EXISTS enterprise_job_incidents;
DROP TABLE IF EXISTS enterprise_job_sst_evaluation_questions;
DROP TABLE IF EXISTS enterprises;

DROP TABLE IF EXISTS internship_supervising_teachers;
DROP TABLE IF EXISTS internship_extra_specializations;
DROP TABLE IF EXISTS internship_mutable_data;
DROP TABLE IF EXISTS internship_weekly_schedules;
DROP TABLE IF EXISTS internship_daily_schedules;
DROP TABLE IF EXISTS internship_transportations;
DROP TABLE IF EXISTS internship_skill_evaluations;
DROP TABLE IF EXISTS internship_skill_evaluation_persons;
DROP TABLE IF EXISTS internship_skill_evaluation_items;
DROP TABLE IF EXISTS internship_skill_evaluation_item_tasks;
DROP TABLE IF EXISTS internship_attitude_evaluations;
DROP TABLE IF EXISTS internship_attitude_evaluation_persons;
DROP TABLE IF EXISTS internship_attitude_evaluation_items;
DROP TABLE IF EXISTS internship_visa_evaluations;
DROP TABLE IF EXISTS internship_visa_evaluation_items;
DROP TABLE IF EXISTS internship_sst_evaluation_info;
DROP TABLE IF EXISTS internship_sst_evaluation_questions;
DROP TABLE IF EXISTS internship_sst_evaluation_persons;
DROP TABLE IF EXISTS post_internship_enterprise_evaluations;
DROP TABLE IF EXISTS post_internship_enterprise_evaluation_skills;
DROP TABLE IF EXISTS internships;

DROP TABLE IF EXISTS teachers_visiting_priorities;

DROP TABLE IF EXISTS schools;
DROP TABLE IF EXISTS school_boards;

SET FOREIGN_KEY_CHECKS = 1;


/***********/
/* GENERIC */
/***********/

CREATE TABLE entities (
    shared_id VARCHAR(36) NOT NULL PRIMARY KEY
);


CREATE TABLE addresses (
    id VARCHAR(36) NOT NULL PRIMARY KEY,
    entity_id VARCHAR(36) NOT NULL,
    civic INT,
    street VARCHAR(100),
    apartment VARCHAR(20),
    city VARCHAR(50),
    postal_code VARCHAR(10),
    latitude FLOAT,
    longitude FLOAT,
    FOREIGN KEY (entity_id) REFERENCES entities(shared_id) ON DELETE CASCADE
);

CREATE TABLE phone_numbers (
    id VARCHAR(36) NOT NULL PRIMARY KEY,
    entity_id VARCHAR(36) NOT NULL,
    phone_number VARCHAR(50) NOT NULL, 
    FOREIGN KEY (entity_id) REFERENCES entities(shared_id) ON DELETE CASCADE
);


/*************************/
/** Admin related tables **/
/*************************/

CREATE TABLE admins (
    id VARCHAR(36) NOT NULL PRIMARY KEY,
    school_board_id VARCHAR(36) NOT NULL,
    has_registered_account BOOLEAN NOT NULL DEFAULT FALSE,
    first_name VARCHAR(50) NOT NULL,
    middle_name VARCHAR(50),
    last_name VARCHAR(50) NOT NULL,
    email VARCHAR(100) NOT NULL,
    access_level INT NOT NULL,
    FOREIGN KEY (id) REFERENCES entities(shared_id) ON DELETE CASCADE
);

/*************************/
/* School related tables */
/*************************/

/**** SCHOOL BOARD ****/
CREATE TABLE school_boards (
    id VARCHAR(36) NOT NULL PRIMARY KEY,
    name VARCHAR(200) NOT NULL,
    logo BLOB,
    cnesst_number VARCHAR(20) NOT NULL,
    FOREIGN KEY (id) REFERENCES entities(shared_id) ON DELETE CASCADE
);

/**** SCHOOLS ****/
CREATE TABLE schools (
    id VARCHAR(36) NOT NULL PRIMARY KEY,
    school_board_id VARCHAR(36) NOT NULL,
    name VARCHAR(200) NOT NULL,
    FOREIGN KEY (school_board_id) REFERENCES school_boards(id),
    FOREIGN KEY (id) REFERENCES entities(shared_id) ON DELETE CASCADE
);



/*************************/
/* People related tables */
/*************************/

/**** Generic persons ****/

CREATE TABLE persons (
    id VARCHAR(36) NOT NULL PRIMARY KEY,
    first_name VARCHAR(50) NOT NULL,
    middle_name VARCHAR(50),
    last_name VARCHAR(50) NOT NULL,
    date_birthday DATE,
    email VARCHAR(100),
    FOREIGN KEY (id) REFERENCES entities(shared_id) ON DELETE CASCADE
);


/**** Students ****/

CREATE TABLE students (
    id VARCHAR(36) NOT NULL PRIMARY KEY,
    version VARCHAR(36) NOT NULL,
    school_board_id VARCHAR(36) NOT NULL,
    school_id VARCHAR(36) NOT NULL,
    photo VARCHAR(255) NOT NULL,
    program INT NOT NULL,
    group_name VARCHAR(20) NOT NULL,
    contact_link VARCHAR(255) NOT NULL,
    FOREIGN KEY (id) REFERENCES persons(id) ON DELETE CASCADE,
    FOREIGN KEY (school_board_id) REFERENCES school_boards(id) ON DELETE CASCADE,
    FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE
);

CREATE TABLE student_contacts (
    student_id VARCHAR(36) NOT NULL,
    contact_id VARCHAR(36) NOT NULL,
    FOREIGN KEY (contact_id) REFERENCES persons(id),
    FOREIGN KEY (student_id) REFERENCES students(id) ON DELETE CASCADE
);


/**** Teachers ****/

CREATE TABLE teachers (
    id VARCHAR(36) NOT NULL PRIMARY KEY,
    school_board_id VARCHAR(36) NOT NULL,
    school_id VARCHAR(36) NOT NULL, 
    has_registered_account BOOLEAN NOT NULL DEFAULT FALSE,
    FOREIGN KEY (id) REFERENCES persons(id) ON DELETE CASCADE,
    FOREIGN KEY (school_board_id) REFERENCES school_boards(id) ON DELETE CASCADE,
    FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE
);

CREATE TABLE teaching_groups (
    teacher_id VARCHAR(36) NOT NULL,
    group_name VARCHAR(20) NOT NULL, 
    FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE CASCADE
);

CREATE TABLE teacher_itineraries (
    id VARCHAR(36) NOT NULL PRIMARY KEY,
    teacher_id VARCHAR(36) NOT NULL,
    date BIGINT NOT NULL,
    FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE CASCADE
);

CREATE TABLE teacher_itinerary_waypoints (
    step_index INT NOT NULL,
    itinerary_id VARCHAR(36) NOT NULL,
    title VARCHAR(50) NOT NULL,
    subtitle VARCHAR(50) NOT NULL,
    address_civic INT,
    address_street VARCHAR(100),
    address_apartment VARCHAR(20),
    address_city VARCHAR(50),
    address_postal_code VARCHAR(10),
    address_latitude FLOAT NOT NULL,
    address_longitude FLOAT NOT NULL,
    visiting_priority INT NOT NULL,
    FOREIGN KEY (itinerary_id) REFERENCES teacher_itineraries(id) ON DELETE CASCADE
);


/******************************/
/* Enterprises related tables */
/******************************/

CREATE TABLE enterprises (
    id VARCHAR(36) NOT NULL PRIMARY KEY,
    version VARCHAR(36) NOT NULL,
    school_board_id VARCHAR(36) NOT NULL,
    name VARCHAR(50) NOT NULL,
    status INT NOT NULL,
    recruiter_id VARCHAR(36), 
    contact_function VARCHAR(255) NOT NULL,
    website VARCHAR(255),
    neq VARCHAR(50),
    FOREIGN KEY (id) REFERENCES entities(shared_id) ON DELETE CASCADE,
    FOREIGN KEY (school_board_id) REFERENCES school_boards(id) ON DELETE CASCADE
);

CREATE TABLE enterprise_contacts(
    enterprise_id VARCHAR(36) NOT NULL,
    contact_id VARCHAR(36) NOT NULL,
    FOREIGN KEY (contact_id) REFERENCES persons(id),
    FOREIGN KEY (enterprise_id) REFERENCES enterprises(id) ON DELETE CASCADE
);

CREATE TABLE enterprise_addresses(
    enterprise_id VARCHAR(36) NOT NULL,
    address_id VARCHAR(36) NOT NULL,
    FOREIGN KEY (address_id) REFERENCES addresses(id),
    FOREIGN KEY (enterprise_id) REFERENCES enterprises(id) ON DELETE CASCADE
);

CREATE TABLE enterprise_headquarters_addresses(
    enterprise_id VARCHAR(36) NOT NULL,
    address_id VARCHAR(36) NOT NULL,
    FOREIGN KEY (address_id) REFERENCES addresses(id),
    FOREIGN KEY (enterprise_id) REFERENCES enterprises(id) ON DELETE CASCADE
);

CREATE TABLE enterprise_phone_numbers(
    enterprise_id VARCHAR(36) NOT NULL,
    phone_number_id VARCHAR(36) NOT NULL,
    FOREIGN KEY (phone_number_id) REFERENCES phone_numbers(id),
    FOREIGN KEY (enterprise_id) REFERENCES enterprises(id) ON DELETE CASCADE
);

CREATE TABLE enterprise_fax_numbers(
    enterprise_id VARCHAR(36) NOT NULL,
    fax_number_id VARCHAR(36) NOT NULL,
    FOREIGN KEY (fax_number_id) REFERENCES phone_numbers(id),
    FOREIGN KEY (enterprise_id) REFERENCES enterprises(id) ON DELETE CASCADE
);

CREATE TABLE enterprise_activity_types(
    enterprise_id VARCHAR(36) NOT NULL,
    activity_type INT NOT NULL,
    FOREIGN KEY (enterprise_id) REFERENCES enterprises(id) ON DELETE CASCADE
);

CREATE TABLE enterprise_jobs(
    id VARCHAR(36) NOT NULL PRIMARY KEY,
    version VARCHAR(36) NOT NULL,
    enterprise_id VARCHAR(36) NOT NULL,
    specialization_id VARCHAR(36) NOT NULL,
    minimum_age INT NOT NULL,
    reserved_for_id VARCHAR(36),
    FOREIGN KEY (enterprise_id) REFERENCES enterprises(id) ON DELETE CASCADE,
    FOREIGN KEY (reserved_for_id) REFERENCES entities(shared_id) ON DELETE SET NULL
);

CREATE TABLE enterprise_job_positions_offered(
    job_id VARCHAR(36) NOT NULL,
    school_id VARCHAR(36) NOT NULL,
    positions INT NOT NULL,
    FOREIGN KEY (job_id) REFERENCES enterprise_jobs(id) ON DELETE CASCADE,
    FOREIGN KEY (school_id) REFERENCES schools(id) ON DELETE CASCADE
);

CREATE TABLE enterprise_job_photos(
    job_id VARCHAR(36) NOT NULL,
    photo MEDIUMBLOB NOT NULL,
    FOREIGN KEY (job_id) REFERENCES enterprise_jobs(id) ON DELETE CASCADE
);

CREATE TABLE enterprise_job_comments(
    job_id VARCHAR(36) NOT NULL,
    teacher_id VARCHAR(36) NOT NULL,
    date BIGINT NOT NULL,
    comment VARCHAR(255) NOT NULL,
    FOREIGN KEY (job_id) REFERENCES enterprise_jobs(id) ON DELETE CASCADE
);

CREATE TABLE enterprise_job_pre_internship_requests(
    id VARCHAR(36) NOT NULL PRIMARY KEY,
    job_id VARCHAR(36) NOT NULL,
    other VARCHAR(255),
    is_applicable BOOLEAN NOT NULL,
    FOREIGN KEY (job_id) REFERENCES enterprise_jobs(id) ON DELETE CASCADE
);

CREATE TABLE enterprise_job_pre_internship_request_items(
    internship_request_id VARCHAR(36) NOT NULL,
    request INT NOT NULL,
    FOREIGN KEY (internship_request_id) REFERENCES enterprise_job_pre_internship_requests(id) ON DELETE CASCADE
);

CREATE TABLE enterprise_job_uniforms(
    job_id VARCHAR(36) NOT NULL,
    status INT NOT NULL,
    uniform VARCHAR(255) NOT NULL,
    FOREIGN KEY (job_id) REFERENCES enterprise_jobs(id) ON DELETE CASCADE
);

CREATE TABLE enterprise_job_protections(
    job_id VARCHAR(36) NOT NULL,
    status INT NOT NULL,
    protection VARCHAR(255) NOT NULL,
    FOREIGN KEY (job_id) REFERENCES enterprise_jobs(id) ON DELETE CASCADE
);

CREATE TABLE enterprise_job_incidents(
    id VARCHAR(36) NOT NULL PRIMARY KEY,
    teacher_id VARCHAR(36) NOT NULL,
    job_id VARCHAR(36) NOT NULL,
    incident_type VARCHAR(20) NOT NULL,
    incident VARCHAR(2000) NOT NULL,
    date BIGINT NOT NULL,
    FOREIGN KEY (job_id) REFERENCES enterprise_jobs(id) ON DELETE CASCADE, 
    FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE CASCADE
);


/******************************/
/* Internships related tables */
/******************************/

CREATE TABLE internships (
    id VARCHAR(36) NOT NULL PRIMARY KEY,
    school_board_id VARCHAR(36) NOT NULL,
    student_id VARCHAR(36) NOT NULL,
    enterprise_id VARCHAR(36) NOT NULL,
    job_id VARCHAR(36) NOT NULL,
    expected_duration BIGINT NOT NULL,
    achieved_duration BIGINT NOT NULL,
    teacher_notes VARCHAR(2000) NOT NULL,
    end_date BIGINT,
    FOREIGN KEY (student_id) REFERENCES students(id), 
    FOREIGN KEY (enterprise_id) REFERENCES enterprises(id),
    FOREIGN KEY (job_id) REFERENCES enterprise_jobs(id),
    FOREIGN KEY (id) REFERENCES entities(shared_id) ON DELETE CASCADE, 
    FOREIGN KEY (school_board_id) REFERENCES school_boards(id) ON DELETE CASCADE
);

CREATE TABLE internship_supervising_teachers (
    internship_id VARCHAR(36) NOT NULL,
    teacher_id VARCHAR(36) NOT NULL,
    is_signatory_teacher BOOLEAN NOT NULL,
    FOREIGN KEY (teacher_id) REFERENCES teachers(id),
    FOREIGN KEY (internship_id) REFERENCES internships(id) ON DELETE CASCADE
);

CREATE TABLE internship_extra_specializations (
    internship_id VARCHAR(36) NOT NULL,
    specialization_id VARCHAR(36) NOT NULL,
    FOREIGN KEY (internship_id) REFERENCES internships(id) ON DELETE CASCADE
);

CREATE TABLE internship_mutable_data (
    id VARCHAR(36) NOT NULL PRIMARY KEY,
    internship_id VARCHAR(36) NOT NULL,
    creation_date BIGINT NOT NULL,
    supervisor_id VARCHAR(36) NOT NULL,
    starting_date BIGINT NOT NULL,
    ending_date BIGINT NOT NULL,
    visit_frequencies VARCHAR(255) NOT NULL,
    FOREIGN KEY (supervisor_id) REFERENCES persons(id),
    FOREIGN KEY (internship_id) REFERENCES internships(id) ON DELETE CASCADE
);

CREATE TABLE internship_weekly_schedules (
    id VARCHAR(36) NOT NULL PRIMARY KEY,
    mutable_data_id VARCHAR(36) NOT NULL,
    starting_date BIGINT NOT NULL,
    ending_date BIGINT NOT NULL,
    FOREIGN KEY (mutable_data_id) REFERENCES internship_mutable_data(id) ON DELETE CASCADE
);

CREATE TABLE internship_daily_schedules (
    id VARCHAR(36) NOT NULL,
    weekly_schedule_id VARCHAR(36) NOT NULL,
    day INT NOT NULL,
    block_index INT NOT NULL,
    starting_hour INT NOT NULL,
    starting_minute INT NOT NULL,
    ending_hour INT NOT NULL,
    ending_minute INT NOT NULL,
    FOREIGN KEY (weekly_schedule_id) REFERENCES internship_weekly_schedules(id) ON DELETE CASCADE
);

CREATE TABLE internship_transportations (
    id VARCHAR(36) NOT NULL,
    transportation INT NOT NULL, 
    FOREIGN KEY (id) REFERENCES internship_mutable_data(id) ON DELETE CASCADE
);

CREATE TABLE internship_skill_evaluations (
    id VARCHAR(36) NOT NULL PRIMARY KEY,
    internship_id VARCHAR(36) NOT NULL,
    date BIGINT NOT NULL,
    skill_granularity INT NOT NULL,
    comments VARCHAR(2000) NOT NULL,
    form_version VARCHAR(36) NOT NULL,
    FOREIGN KEY (internship_id) REFERENCES internships(id) ON DELETE CASCADE
);

CREATE TABLE internship_skill_evaluation_persons (
    evaluation_id VARCHAR(36) NOT NULL,
    person_name VARCHAR(100) NOT NULL,
    FOREIGN KEY (evaluation_id) REFERENCES internship_skill_evaluations(id) ON DELETE CASCADE
);

CREATE TABLE internship_skill_evaluation_items (
    id VARCHAR(36) NOT NULL PRIMARY KEY,
    evaluation_id VARCHAR(36) NOT NULL,
    job_id VARCHAR(36) NOT NULL,
    skill_name VARCHAR(1000) NOT NULL,
    appreciation INT NOT NULL,
    comments VARCHAR(2000),
    FOREIGN KEY (evaluation_id) REFERENCES internship_skill_evaluations(id) ON DELETE CASCADE
);

CREATE TABLE internship_skill_evaluation_item_tasks (
    id VARCHAR(36) NOT NULL PRIMARY KEY,
    evaluation_item_id VARCHAR(36) NOT NULL,
    title VARCHAR(1000) NOT NULL,
    level INT NOT NULL,
    FOREIGN KEY (evaluation_item_id) REFERENCES internship_skill_evaluation_items(id) ON DELETE CASCADE
);

CREATE TABLE internship_attitude_evaluations (
    id VARCHAR(36) NOT NULL PRIMARY KEY,
    internship_id VARCHAR(36) NOT NULL,
    date BIGINT NOT NULL,
    comments VARCHAR(2000) NOT NULL,
    form_version VARCHAR(36) NOT NULL,
    FOREIGN KEY (internship_id) REFERENCES internships(id) ON DELETE CASCADE   
);

CREATE TABLE internship_attitude_evaluation_persons (
    evaluation_id VARCHAR(36) NOT NULL,
    person_name VARCHAR(100) NOT NULL,
    FOREIGN KEY (evaluation_id) REFERENCES internship_attitude_evaluations(id) ON DELETE CASCADE
);

CREATE TABLE internship_attitude_evaluation_items (
    id VARCHAR(36) NOT NULL PRIMARY KEY,
    evaluation_id VARCHAR(36) NOT NULL,
    inattendance INT NOT NULL,
    ponctuality INT NOT NULL,
    sociability INT NOT NULL,
    politeness INT NOT NULL,
    motivation INT NOT NULL,
    dressCode INT NOT NULL,
    quality_of_work INT NOT NULL,
    productivity INT NOT NULL,
    autonomy INT NOT NULL,
    cautiousness INT NOT NULL,
    general_appreciation INT NOT NULL,
    FOREIGN KEY (evaluation_id) REFERENCES internship_attitude_evaluations(id) ON DELETE CASCADE
);

CREATE TABLE internship_visa_evaluations (
    id VARCHAR(36) NOT NULL PRIMARY KEY,
    internship_id VARCHAR(36) NOT NULL,
    date BIGINT NOT NULL,
    form_version VARCHAR(36) NOT NULL,
    FOREIGN KEY (internship_id) REFERENCES internships(id) ON DELETE CASCADE
);

CREATE TABLE internship_visa_evaluation_items (
    id VARCHAR(36) NOT NULL PRIMARY KEY,
    evaluation_id VARCHAR(36) NOT NULL,
    inattendance INT NOT NULL,
    ponctuality INT NOT NULL,
    sociability INT NOT NULL,
    politeness INT NOT NULL,
    motivation INT NOT NULL,
    dressCode INT NOT NULL,
    quality_of_work INT NOT NULL,
    productivity INT NOT NULL,
    autonomy INT NOT NULL,
    cautiousness INT NOT NULL,
    general_appreciation INT NOT NULL,
    FOREIGN KEY (evaluation_id) REFERENCES internship_visa_evaluations(id) ON DELETE CASCADE
);

CREATE TABLE internship_sst_evaluation_info(
    internship_id VARCHAR(36) NOT NULL,
    date BIGINT NOT NULL,
    FOREIGN KEY (internship_id) REFERENCES internships(id) ON DELETE CASCADE
);

CREATE TABLE internship_sst_evaluation_persons (
    internship_id VARCHAR(36) NOT NULL,
    person_name VARCHAR(100) NOT NULL,
    FOREIGN KEY (internship_id) REFERENCES internships(id) ON DELETE CASCADE
);

CREATE TABLE internship_sst_evaluation_questions(
    internship_id VARCHAR(36) NOT NULL,
    question VARCHAR(255) NOT NULL,
    answers VARCHAR(2000) NOT NULL,
    FOREIGN KEY (internship_id) REFERENCES internships(id) ON DELETE CASCADE
);

CREATE TABLE post_internship_enterprise_evaluations (
    id VARCHAR(36) NOT NULL PRIMARY KEY,
    date BIGINT NOT NULL,
    internship_id VARCHAR(36) NOT NULL,
    task_variety FLOAT NOT NULL,
    training_plan_respect FLOAT NOT NULL,
    autonomy_expected FLOAT NOT NULL,
    efficiency_expected FLOAT NOT NULL,
    supervision_style FLOAT NOT NULL,
    ease_of_communication FLOAT NOT NULL,
    absence_acceptance FLOAT NOT NULL,
    supervision_comments VARCHAR(2000) NOT NULL,
    acceptance_tsa FLOAT NOT NULL,
    acceptance_language_disorder FLOAT NOT NULL,
    acceptance_intellectual_disability FLOAT NOT NULL,
    acceptance_physical_disability FLOAT NOT NULL,
    acceptance_mental_health_disorder FLOAT NOT NULL,
    acceptance_behavior_difficulties FLOAT NOT NULL,
    FOREIGN KEY (internship_id) REFERENCES internships(id) ON DELETE CASCADE
);

CREATE TABLE teachers_visiting_priorities (
    teacher_id VARCHAR(36) NOT NULL,
    internship_id VARCHAR(36) NOT NULL,
    visiting_priority INT NOT NULL,
    FOREIGN KEY (teacher_id) REFERENCES teachers(id) ON DELETE CASCADE,
    FOREIGN KEY (internship_id) REFERENCES internships(id) ON DELETE CASCADE
);

CREATE TABLE post_internship_enterprise_evaluation_skills (
    post_evaluation_id VARCHAR(36) NOT NULL,
    skill_name VARCHAR(100) NOT NULL,
    FOREIGN KEY (post_evaluation_id) REFERENCES post_internship_enterprise_evaluations(id) ON DELETE CASCADE
);
