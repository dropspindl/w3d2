PRAGMA foreign_keys = ON;

DROP TABLE if exists question_likes;
DROP TABLE if exists replies;
DROP TABLE if exists question_follows;
DROP TABLE if exists questions;
DROP TABLE if exists users;

CREATE TABLE users (
  id integer PRIMARY KEY,
  fname character varying(30),
  lname character varying(30)
);

CREATE TABLE questions (
  id integer PRIMARY KEY,
  title character varying,
  body character varying,
  author integer NOT NULL,
  
  FOREIGN KEY(author) REFERENCES users(id)
);

CREATE TABLE question_follows (
  id integer PRIMARY KEY,
  question_id integer NOT NULL,
  follower integer NOT NULL,
  
  FOREIGN KEY(question_id) REFERENCES questions(id),
  FOREIGN KEY(follower) REFERENCES users(id)
);

CREATE TABLE replies (
  id integer PRIMARY KEY,
  question_id integer NOT NULL,
  parent integer,
  user_id integer NOT NULL,
  body character varying,
  
  FOREIGN KEY(question_id) REFERENCES questions(id),
  FOREIGN KEY(parent) REFERENCES replies(id),
  FOREIGN KEY(user_id) REFERENCES users(id)
);

CREATE TABLE question_likes (
  id integer PRIMARY KEY,
  user_id integer NOT NULL,
  question_id integer NOT NULL,
  
  FOREIGN KEY(question_id) REFERENCES questions(id),
  FOREIGN KEY(user_id) REFERENCES users(id)
);



INSERT INTO 
  users('fname', 'lname')
VALUES 
  ('Erica', 'Edelman'),
  ('Sue', 'Park');
  
  
INSERT INTO 
  questions('title', 'body', 'author')
VALUES
  ('Why doesn''t this work?', 'I tried a lot of things and it does not work! HELP!', 1), 
  ('Why doesn''t this work?', 'Computer not turning on!!', 1),
  ('Life Advice', 'What should I do with my life??', 2);
  
  
INSERT INTO 
  question_follows('question_id', 'follower')
VALUES 
  (1, 2),
  (1, 1),
  (2, 2);
  
INSERT INTO 
  replies('question_id', 'parent', 'user_id', 'body')
VALUES 
  (1, null, 2, 'What do you need help with?'),
  (2, 1, 2, 'Press the Power Button'),
  (1, 1, 1, 'I can''t turn on the computer');


