import static org.vertx.testtools.VertxAssert.*
import org.vertx.groovy.testtools.VertxTests // And import static the VertxTests script
import groovy.json.*
import java.nio.file.Files
import java.nio.file.Paths
import java.nio.file.attribute.PosixFilePermissions

logger = container.logger
home = "./build/mods/${System.getProperty('vertx.modulename')}"

jsonSlurper = new JsonSlurper()

config = jsonSlurper.parse(new File('conf.json'))

def send(adrs, msg, handler = null) {
  if (!handler) {
    vertx.eventBus.send(adrs, msg)
    logger.info "${this.class.name}: SEND:${msg} TO ${adrs}"
  } else {
    vertx.eventBus.send(adrs, msg) {
      logger.info "${this.class.name}: SEND:${msg} TO ${adrs} REPLY:${it.body}"
      handler.call(it.body)
    }
  }
}

def request(count = 1) {
  def req
  switch (count) {
  case 1://
    req = httpClient.put("/") { println "PUT RESULT: ${it.statusCode}" }
    break
  case 2: //
    req = httpClient.post("/") { println "POST RESULT: ${it.statusCode}" }
    break
  case 3: //
    req = httpClient.get("/") { println "GET RESULT: ${it.statusCode}" }
    break
  case 4: //
    req = httpClient.put("/path/to/put/data") { println "PUT RESULT: ${it.statusCode}" }
    break
  case 5: //
    req = httpClient.post("/path/to/data") { println "POST RESULT: ${it.statusCode}" }
    break
  case 6: //
    req = httpClient.get("/favicon.ico") { println "GET RESULT: ${it.statusCode}" }
    break
  default: //
    testComplete()
  }
  req.end()
  ++count
}


def timeout() {
  def next = request()
  vertx.setPeriodic(500) { timeout(next) }
}

// The test methods must being with "test"

def testOut() {
  // generate HTTP client for sending report.
  def param = [port:config.destport, host: 'localhost', keepAlive:false]
  if (config.ssl) { param.SSL = true; param.trustAll = true }
  httpClient = vertx.createHttpClient(param)
  def next = request()
  vertx.setPeriodic(500) { timeout(next) }
}







// Make sure you initialize
VertxTests.initialize(this)

// The script is execute for each test, so this will deploy the module for each one
// Deploy the module - the System property `vertx.modulename` will contain the name of the module so you
// don't have to hardecode it in your tests
container.deployModule(System.getProperty("vertx.modulename"), config) { asyncResult ->
  if (!asyncResult.succeeded) {
    logger.fatal asyncResult.cause()
    assertTrue(asyncResult.succeeded) // stop test.
  } else {
    logger.info asyncResult.result()
    // If deployed correctly then start the tests!
    VertxTests.startTests(this)
  }
}
