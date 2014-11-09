/*
 *   Copyright (c) Genetec Corporation. All Rights Reserved.
 */

package jp.survei.ssltest

import jp.survei.base.BusMod

import org.vertx.java.core.Future

import groovy.json.*

class Server extends BusMod {

  def spec = [optional:[destport:10080, ssl:true, keystore:'surveikeystore', keypass:'f42d5fa9-d1fa-42']];

  def server
  def jsonSlurper = new JsonSlurper()

  // handler request.
  def handleRequest(req) {
    req.bodyHandler { body ->
      info "INCOMING: FROM:${req.remoteAddress} TO ${req.absoluteURI} METHOD:${req.method}"
      req.response.end() // response.
    }
  }


  @Override def start(Future<Void> sr) {
    super.start()
    logger.info "Start Server"
    def confresult = chkconfig(config, spec)   // verify configuration.
    logger.debug "chkconfig returns ${confresult}."
    if (confresult) sr.setFailure(confresult) // something wrong.
    else {
      def param = null
      if (config.ssl) param = [SSL:true, keyStorePath:config.keystore, keyStorePassword:config.keypass]
      server = vertx.createHttpServer(param)
      server.requestHandler{ req -> handleRequest(req) }
      server.listen(config.destport) {
        info "START Http Server with ${param}"
        if (!config.useclient) sr.setResult(null)
        else {
          container.deployVerticle('groovy:jp.survei.ssltest.Client', config) {
            if (!it.succeeded) sr.setFailure(new Exception(it.cause())) // something wrong.
            else sr.setResult(null)
          }
        }
      }
    }
  }

  @Override def stop() {
    logger.info "Server Stopped."
  }
}
