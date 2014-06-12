import static org.vertx.testtools.VertxAssert.*
import org.vertx.groovy.testtools.VertxTests // And import static the VertxTests script
import groovy.json.*
import java.nio.file.Files
import java.nio.file.Paths
import java.nio.file.attribute.PosixFilePermissions

def send(adrs, msg, handler) {
  vertx.eventBus.send(adrs, msg) {
    logger.info "SEND:${msg}  => REPLY:${it.body}"
    handler.call(it)
  }
}


// The test methods must being with "test"

// example.
def testOut() {
  println "${new File('.').getAbsolutePath()}"
  println "vertx is ${vertx.getClass().getName()}"
  println "Module: ${System.getProperty('vertx.modulename')}"
  testComplete()
}







// Make sure you initialize
VertxTests.initialize(this)

// The script is execute for each test, so this will deploy the module for each one
// Deploy the module - the System property `vertx.modulename` will contain the name of the module so you
// don't have to hardecode it in your tests
container.deployModule(System.getProperty("vertx.modulename"), { asyncResult ->
  // Deployment is asynchronous and this handler will be called when it's complete (or failed)
  assertTrue(asyncResult.succeeded)
  assertNotNull("deploymentID should not be null", asyncResult.result())
  if (!asyncResult.succeeded) {
    println asyncResult.cause()
  } else {
    println asyncResult.result()
  }
  // If deployed correctly then start the tests!
  VertxTests.startTests(this)
})
