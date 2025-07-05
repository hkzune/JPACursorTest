package jpacursortest;

import jakarta.ws.rs.ApplicationPath;
import org.glassfish.jersey.server.ResourceConfig;

@ApplicationPath("/webapi")
public class ApplicationSettings extends ResourceConfig {

    public ApplicationSettings() {
        super();
        this.packages("jpacursortest");
        this.register("jpacursortest");
    }
}
