class SessionStruct < Struct.new(:src_ip, :src_port, :dst_ip, :dst_port, :last_touched_at)
end
