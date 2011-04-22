#Encoding: UTF-8

OpenRubyRMK::Karfunkel::SM::Request.define :OpenProject do
  
  attribute :file
  
  def execute(client)
    raise(Errors::InvalidParameter, "No project file given!") unless self[:file]
    raise(Errors::InvalidParameter, "'#{self[:file]}' is not a file!") unless File.file?(self[:file])
    
    project = PM::Project.load(self[:file])
    Karfunkel.log_info("[#{client}] Loading project '#{project.name}'.")
    Karfunkel.projects << project
    
    answer :processing
    broadcast :load_project, :mapset_extraction => 0, :char_extraction => 0
    
    #TODO: Not sure--when the Command containing this Request gets GC’ed, is
    #this timer then eliminated...? If Karfunkel crashes with obscure
    #exceptions (which I have not seen yet), this may be the case...
    timer = EventMachine.add_periodic_timer(2) do
      if project.loaded?
        #HIER! answer funktioniert nur einmal!
      else
        broadcast :load_project, project.loading
      end
    end
  end
  
end