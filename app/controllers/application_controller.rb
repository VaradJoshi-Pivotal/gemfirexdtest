require 'jdbc/derby'
require "rubygems"
require "java"


class ApplicationController < ActionController::Base
    protect_from_forgery

    def openconn
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
            connSelect = java.sql.DriverManager.get_connection(userurl, "vjoshi", "p1v0tal")
            stmtSelect = connSelect.create_statement

            # Define the query
            selectquery = "select * from snapshots"

            # Execute the query
            rsS = stmtSelect.execute_query(selectquery)

            # For each row returned do some stuff
            while (rsS.next) do
                sid = rsS.getObject("sid")
                stimestamp = rsS.getObject("stimestamp")
            end
        end
        # Close off the connection
        stmtSelect.close
        connSelect.close
        return nil
    end

end
