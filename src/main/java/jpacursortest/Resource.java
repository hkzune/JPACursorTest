package jpacursortest;

import jakarta.inject.Inject;
import jakarta.ws.rs.POST;
import jakarta.ws.rs.Path;


@Path("resource")
public class Resource {

    @Inject
    private Application app;

    @POST
    @Path("test")
    public void test() {
        app.execute();
    }
}
