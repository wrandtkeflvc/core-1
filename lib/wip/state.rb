require 'wip'
require 'wip/snafu'
require 'wip/task'
require 'wip/process'

class Wip

  def state

    if running? then 'running'
    elsif stopped? then 'stopped'
    elsif snafu? then 'snafu'
    elsif done? then 'complete'
    else 'idle'
    end

  end

end