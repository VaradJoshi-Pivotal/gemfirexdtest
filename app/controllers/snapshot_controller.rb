require 'jdbc/derby'
require "rubygems"
require "java"

class SnapshotController < ApplicationController
  def show
  end

  def getdata
        debugger
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

            # Define the query
            stmtSelect = connSelect.create_statement
            selectquery = "select min(id), max(id) from snapshots"
            # Execute the query
            rsS = stmtSelect.execute_query(selectquery)

            # For each row returned do some stuff
            minid = 1
            maxid = 1
            while (rsS.next) do
                minid = rsS.getObject("1")
                maxid = rsS.getObject("2")
            end
            stmtSelect.close

            # Define the query
            stmtSelect = connSelect.create_statement
            selectquery = "select * from snapshots"
            # Execute the query
            rsS = stmtSelect.execute_query(selectquery)

            timestamps = Array.new( maxid-minid+1 )
            # For each row returned do some stuff
            while (rsS.next) do
                id = rsS.getObject("id")
                timestamps[id-minid] = rsS.getObject("stimestamp").to_s
            end
            stmtSelect.close

            # Define the query
            stmtSelect = connSelect.create_statement
            #selectquery = "select o.name, o.numopen, s.stimestamp from ownerdata as o, snapshots as s where o.sid = s.id"
            selectquery = "select name, numopen, sid from ownerdata"
            # Execute the query
            rsS = stmtSelect.execute_query(selectquery)

            ownerToIdx = Hash.new
			ownerdata = Array.new
            # For each row returned do some stuff
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
        render json: {timestamps: timestamps, ownerdata: ownerdata}
  end
end
