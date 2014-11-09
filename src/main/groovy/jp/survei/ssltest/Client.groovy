/*
 *   Copyright (c) Genetec Corporation. All Rights Reserved.
 */

package jp.survei.ssltest

import jp.survei.base.BusMod

import org.vertx.java.core.Future

class Client extends BusMod {

  def spec = [:]
  def count = 0
  def httpClient

  def request() {
    def req
    switch (count % 6) {
    case 0: //
      req = httpClient.get("/maumau?a=b&c=d") { println "GET RESULT: ${it.statusCode}" }
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
    }
    req.end()
    ++count
    if (50 < count) container.exit()
  }

  def timeout() {
    info "TIMEOUT"
    request()
    vertx.setPeriodic(500) { timeout() }
  }

  @Override def start(Future<Void> sr) {
    super.start()
    logger.info "Start Client"
    def confresult = chkconfig(config, spec)   // verify configuration.
    logger.debug "chkconfig returns ${confresult}."
    if (confresult) sr.setFailure(confresult) // something wrong.
    else {
      // generate HTTP client for sending report.
      def param = [port:config.destport, host: 'localhost', keepAlive:false]
      if (config.ssl) { param.SSL = true; param.trustAll = true }
      info "START Client with ${param}"
      httpClient = vertx.createHttpClient(param)
      request()
      vertx.setPeriodic(500) { timeout() }
      sr.setResult(null)
    }
  }

  @Override def stop() {
    logger.info "Client Stopped."
  }
}
