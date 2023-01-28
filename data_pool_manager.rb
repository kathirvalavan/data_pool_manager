class PoolTimeoutError < ::RuntimeError; end


class StackPool

  def initialize
    @atomic_lock = Mutex.new
    @pool_data = Array.new
    @resource = Thread::ConditionVariable.new
  end

  def push(data)
    @atomic_lock.synchronize do
      @pool_data << data
    end
  end

  def pop(timeout = 0.5)
    data = nil
    deadline = current_time + timeout

    @mutex.synchronize do
      loop do
        data = fetch_data
        break unless data.nil?
        raise PoolTimeoutError if (deadline - current_time ) < 0
        @resource.wait(@mutex, timeout)
      end
    end
    data
  end

  def fetch_data
    @pool_data.pop
  end

  def clear
    @atomic_lock.synchronize do
      @pool_data.clear
    end
  end

  def create(block)
    objects = block.call
    (objects || []).each do |data|
      push(data)
    end
  end

  def current_time
    Process.clock_gettime(Process::CLOCK_MONOTONIC)
  end
end