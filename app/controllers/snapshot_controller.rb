require 'jdbc/derby'
require "rubygems"
require "java"

class SnapshotController < ApplicationController
  def show
  end

  def getdata
        #debugger
        #ActiveRecord::Base.establish_connection(
        #    :adapter => 'jdbc',
        #    :username => 'vjoshi',
        #    :password => 'p1v0tal',
        #    :driver => 'com.pivotal.gemfirexd.jdbc.EmbeddedDriver',
        #    :url => 'jdbc:gemfirexd://localhost:1527/'
        #    )

        begin
            # Prep the connection
            # Java::com.pivotal.gemfirexd.jdbc.EmbeddedDriver
            Java::com.pivotal.gemfirexd.jdbc.ClientDriver
            userurl = "jdbc:gemfirexd://localhost:1527/"
            connSelect = java.sql.DriverManager.get_connection(userurl, "app", "app")

            # Get the miniumn and maximum ids in the snapshot table
            stmtSelect = connSelect.create_statement
            selectquery = "select min(id), max(id) from snapshots"
            # Execute the query
            rsS = stmtSelect.execute_query(selectquery)

            # iterate over the resultset. Min/max are returned as columns 1 and 2
            minid = 1
            maxid = 1
            while (rsS.next) do
                minid = rsS.getObject("1")
                maxid = rsS.getObject("2")
            end
            stmtSelect.close

            # Get all the ids and timestamps from snapshot table
            stmtSelect = connSelect.create_statement
            selectquery = "select * from snapshots"
            # Execute the query
            rsS = stmtSelect.execute_query(selectquery)

            timestamps = Array.new( maxid-minid+1 )
            # iterate over the resultset and get id and stimestamp columns
            while (rsS.next) do
                id = rsS.getObject("id")
				# timestamp is of format 'yyyy-mm-dd hh:mm:ss.mmm'
				# we are interested in only the 'yyyy-mm-dd hh:mm' part of it
				# so truncate it to 16th character
				ts = rsS.getObject("stimestamp").to_s
                timestamps[id-minid] = ts[0,16]
            end
            stmtSelect.close

            # Get the total number of open, incoming and outgoing defects for each snapshot
            stmtSelect = connSelect.create_statement
            selectquery = "select sid, sum(numopen), sum(numclosed+numdeferred), sum(numnew+numreopened) from ownerdata group by sid"
            # Execute the query
            rsS = stmtSelect.execute_query(selectquery)

            numop = Array.new( maxid-minid+1 )
            numin = Array.new( maxid-minid+1 )
            numout = Array.new( maxid-minid+1 )
            # Iterate over the resultset. numopen, numin and numout are columns 2, 3, and 4
            while (rsS.next) do
                id = rsS.getObject("sid")
                numop[id-minid] = rsS.getObject("2")
                numout[id-minid] = rsS.getObject("3")
                numin[id-minid] = rsS.getObject("4")
            end
            stmtSelect.close

            # Get the name, number of open defects and snapshot id from ownerdata
            stmtSelect = connSelect.create_statement
            selectquery = "select name, numopen, sid from ownerdata"
            # Execute the query
            rsS = stmtSelect.execute_query(selectquery)

            ownerToIdx = Hash.new
			ownerdata = Array.new
            # Iterate over resultset and gather data by owner and by snapshot
            while (rsS.next) do
                name = rsS.getObject("name")
                numopen = rsS.getObject("numopen")
                sid = rsS.getObject("sid")
                idx = ownerToIdx[name]
				currData = nil
                if (idx) then
					currData = ownerdata[idx]
				end
				if (currData == nil) then
					currData = Hash.new
					ownerdata.push(currData)
					ownerToIdx[name] = ownerdata.size - 1
					currData["name"] = name
					currData["data"] = Array.new(maxid-minid+1, 0)
				end
                currData["data"][sid-minid] = numopen
            end
            stmtSelect.close
        end
        # Close off the connection
        connSelect.close
        render json: {timestamps: timestamps, ownerdata: ownerdata, numopen: numop, numin: numin, numout: numout}
  end
end
