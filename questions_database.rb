require 'sqlite3'
require 'singleton'
require 'byebug'

class QuestionsDBConnection < SQLite3::Database
  include Singleton

  def initialize
    super('questions.db')
    self.type_translation = true
    self.results_as_hash = true
  end
end





class Users
  attr_accessor :id, :fname, :lname
  
  def self.all
    data = QuestionsDBConnection.instance.execute("SELECT * FROM questions")
    data.map { |datum| Users.new(datum) }
  end
  
  def initialize(options)
    @id = options['id']
    @fname = options['fname']
    @lname = options['lname']
  end 
  
  def self.find_by_id(id)
    user = QuestionsDBConnection.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        users
      WHERE
        id = ?
    SQL
    return nil if user.empty?

    Users.new(user.first)
  end
  
  def self.find_by_name(fname, lname)
    user = QuestionsDBConnection.instance.execute(<<-SQL, fname, lname)
      SELECT
        *
      FROM
        users
      WHERE
        fname = ?
      AND
        lname = ?
    SQL
    
    return nil if user.empty?
    Users.new(user.first)
  end
  
  def authored_questions
    Questions.find_by_author_id(self.id)
  end
  
  def authored_replies 
    Replies.find_by_user_id(self.id)
  end
  
  def followed_questions
    QuestionFollows.followed_questions_for_user_id(self.id)
  end
  
end




class Questions
  attr_accessor :id, :title, :body, :author

  def self.all
    data = QuestionsDBConnection.instance.execute("SELECT * FROM questions")
    data.map { |datum| Questions.new(datum) }
  end

  def self.find_by_id(id)
    question = QuestionsDBConnection.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        questions
      WHERE
        id = ?
    SQL
    return nil if question.empty?

    Questions.new(question.first)
  end
  
  
  def self.find_by_author_id(author_id)
    question = QuestionsDBConnection.instance.execute(<<-SQL, author_id)
      SELECT
        *
      FROM
        questions
      WHERE
        author = ?
    SQL
    return nil if question.empty?

    results = []
    question.each do |question_hash|
      results << Questions.new(question_hash)
    end
    results
  end

  
  def initialize(options)
    @id = options['id']
    @title = options['title']
    @body = options['body']
    @author = options['author']
  end
  
  def author 
    @author
  end
  
  def replies 
    Replies.find_by_question_id(self.id)
  end 
  
  def followers
    QuestionFollows.followers_for_question_id(self.id)
  end
  
end 




class QuestionFollows 
  attr_accessor :id, :question_id, :followers
  
  def self.all
    data = QuestionsDBConnection.instance.execute("SELECT * FROM question_follows")
    data.map { |datum| QuestionFollows.new(datum) }    
  end
  
  def self.find_by_id(id)
    question_follow = QuestionsDBConnection.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        question_follows
      WHERE
        id = ?
    SQL
    return nil if question_follow.empty?

    QuestionFollows.new(question_follow.first)
  end
  
  def self.followers_for_question_id(q_id)
    question_followers = QuestionsDBConnection.instance.execute(<<-SQL, q_id)
      SELECT
        *
      FROM
        question_follows
      JOIN users ON question_follows.follower = users.id
      WHERE
        question_id = ?
    SQL
    
    results = []
    question_followers.each do |follower_hash|
      results << Users.new(follower_hash)
    end
    results
  end
  
  def self.followed_questions_for_user_id(u_id)
    followed_questions = QuestionsDBConnection.instance.execute(<<-SQL, u_id)
      SELECT
        *
      FROM
        question_follows
      JOIN questions ON question_follows.question_id = questions.id
      WHERE
        follower = ?
    SQL
    
    results = []
    followed_questions.each do |followed_hash|
      results << Questions.new(followed_hash)
    end
    results
  end
  
  def self.most_followed_questions(n) 
    most_followed = QuestionsDBConnection.instance.execute(<<-SQL, n)
      SELECT
        questions.id
      FROM
        question_follows
      JOIN questions ON question_follows.question_id = questions.id
      GROUP BY questions.id 
      ORDER BY COUNT(question_follows.follower) DESC
      LIMIT ?
    SQL
    
    most_followed.map do |q_hash| 
      Questions.find_by_id(q_hash["id"])
    end 
  end 
  
  def initialize(options)
    @id = options['id']
    @question_id = options['question_id']
    @followers = options['followers']
  end 
  
end




class Replies
  attr_accessor :id, :question_id, :parent, :user_id, :body
  
  def self.find_by_id(id)
    reply = QuestionsDBConnection.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        replies
      WHERE
        id = ?
    SQL
    return nil if reply.empty?

    Replies.new(reply.first)
  end
  
  def self.find_by_user_id(user_id)
    reply_array = QuestionsDBConnection.instance.execute(<<-SQL, user_id)
      SELECT
        *
      FROM
        replies
      WHERE
        user_id = ?
    SQL
    return nil if reply_array.empty?
    
    results = []
    reply_array.each do |reply_hash|
      results << Replies.new(reply_hash)
    end
    results
  end
  
  def self.find_by_question_id(q_id)
    reply_array = QuestionsDBConnection.instance.execute(<<-SQL, q_id)
      SELECT
        *
      FROM
        replies
      WHERE
        question_id = ?
    SQL
    return nil if reply_array.empty?
    
    results = []
    reply_array.each do |reply_hash|
      results << Replies.new(reply_hash)
    end
    results
  end 
  
  def initialize(options)
    @id = options['id']
    @question_id = options['question_id']
    @parent = options['parent']
    @user_id = options['user_id']
    @body = options['body']
  end 
  
  def author 
    self.user_id  
  end
  
  def question 
    self.question_id 
  end 
  
  def parent_reply 
    self.parent
  end
  
  def child_replies 
    children = QuestionsDBConnection.instance.execute(<<-SQL, self.id)
      SELECT *
      FROM replies 
      WHERE parent = ?
    SQL
    
    results = [] 
    children.each do |child_hash|
      results << Replies.new(child_hash)
    end 
    results
  end 
      
end





class QuestionLikes
  attr_accessor :id, :user_id, :question_id
  
  def initialize(options)
    @id = options['id']
    @question_id = options['question_id']
    @user_id = options['user_id']
  end 
  
  def self.find_by_id(id)
    question_like = QuestionsDBConnection.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        question_likes
      WHERE
        id = ?
    SQL
    return nil if question_like.empty?

    QuestionLikes.new(question_like.first)
  end
end
  

  # def create
  #   raise "#{self} already in database" if @id
  #   PlayDBConnection.instance.execute(<<-SQL, @title, @year, @playwright_id)
  #     INSERT INTO
  #       plays (title, year, playwright_id)
  #     VALUES
  #       (?, ?, ?)
  #   SQL
  #   @id = PlayDBConnection.instance.last_insert_row_id
  # end
  # 
  # def update
  #   raise "#{self} not in database" unless @id
  #   PlayDBConnection.instance.execute(<<-SQL, @title, @year, @playwright_id, @id)
  #     UPDATE
  #       plays
  #     SET
  #       title = ?, year = ?, playwright_id = ?
  #     WHERE
  #       id = ?
  #   SQL
  # end

