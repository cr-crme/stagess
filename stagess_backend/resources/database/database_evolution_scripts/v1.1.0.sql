/******************************/
/* Enterprises related tables */
/******************************/

UPDATE enterprises 
    SET website = '' 
    WHERE website IS NULL;

UPDATE enterprises
    SET neq = ''
    WHERE neq IS NULL;

ALTER TABLE enterprises
    MODIFY website VARCHAR(200) NOT NULL,
    MODIFY neq VARCHAR(50) NOT NULL;

DROP TABLE IF EXISTS enterprise_job_uniforms;
DROP TABLE IF EXISTS enterprise_job_protections;


/**************************/
/* Persons related tables */
/**************************/

UPDATE persons
    SET email = '' 
    WHERE email IS NULL;

ALTER TABLE persons
    MODIFY email VARCHAR(200) NOT NULL,
    DELETE middle_name;



/*************************/
/* Admins related tables */
/*************************/

INSERT INTO persons (id, first_name, last_name, email)
    SELECT id, first_name, last_name, email
    FROM admins;

ALTER TABLE admins
    DELETE first_name,
    DELETE middle_name,
    DELETE last_name,
    DELETE email;


/**************************/
/* Users related tables */
/**************************/

CREATE TABLE users (
    id VARCHAR(36) NOT NULL PRIMARY KEY,
    email VARCHAR(200) NOT NULL UNIQUE,
    FOREIGN KEY (id) REFERENCES entities(shared_id) ON DELETE CASCADE
);

INSERT INTO users (id, email)
    SELECT t.id, p.email
    FROM teachers t
    JOIN persons p ON t.id = p.id;

INSERT INTO users (id, email)
    SELECT t.id, p.email
    FROM admins t
    JOIN persons p ON t.id = p.id;



/* Migrate the enterprise_job_incidents table from teacher_id to user_id */
START TRANSACTION;

RENAME TABLE enterprise_job_incidents TO enterprise_job_incidents_bak;

CREATE TABLE enterprise_job_incidents(
    id VARCHAR(36) NOT NULL PRIMARY KEY,
    user_id VARCHAR(36) NOT NULL,
    job_id VARCHAR(36) NOT NULL,
    incident_type VARCHAR(50) NOT NULL,
    incident VARCHAR(2000) NOT NULL,
    date BIGINT NOT NULL,
    FOREIGN KEY (job_id) REFERENCES enterprise_jobs(id) ON DELETE CASCADE, 
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

INSERT INTO enterprise_job_incidents (id, user_id, job_id, incident_type, incident, date)
    SELECT id, teacher_id, job_id, incident_type, incident, date
    FROM enterprise_job_incidents_bak;

DROP TABLE enterprise_job_incidents_bak;

COMMIT;


/* Migrate the enterprise_job_comments table from teacher_id to user_id */
START TRANSACTION;

RENAME TABLE enterprise_job_comments TO enterprise_job_comments_bak;

CREATE TABLE enterprise_job_comments(
    job_id VARCHAR(36) NOT NULL,
    user_id VARCHAR(36) NOT NULL,
    date BIGINT NOT NULL,
    comment VARCHAR(2000) NOT NULL,
    FOREIGN KEY (job_id) REFERENCES enterprise_jobs(id) ON DELETE CASCADE,
    FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
);

INSERT INTO enterprise_job_comments (job_id, user_id, date, comment)
    SELECT job_id, teacher_id, date, comment
    FROM enterprise_job_comments_bak;

DROP TABLE enterprise_job_comments_bak;

COMMIT;