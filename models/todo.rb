DB = Sequel.connect('sqlite://todolist-ruby.db')

class Todo < Sequel::Model
  def before_create
    self.created_at ||= Time.now
    super
  end

  def before_save
    self.updated_at ||= Time.now
    super
  end
end