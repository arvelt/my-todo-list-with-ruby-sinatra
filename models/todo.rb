DB = Sequel.connect('sqlite://todolist-ruby.db')
Sequel::Model.plugin :json_serializer

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
