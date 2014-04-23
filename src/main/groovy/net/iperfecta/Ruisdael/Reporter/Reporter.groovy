/*
 *   Copyright (c) Genetec Corporation. All Rights Reserved.
 */
package net.iperfecta.Ruisdael.Reporter

import net.iperfecta.Ruisdael.Base.BusMod


abstract class Reporter extends BusMod {

  String address // send 
  Long starttime // when I start to work
  Long sendreport // number of sending report.
  def target = [] // targets who I monitoring.
  def pendingReport = [] // reports that not send.

  // Override me!
  abstract def startReporting()

  // Get mac address for temporary ID.
  def getMacAddress() {
    def mac = []
    def hostAddress = InetAddress.getLocalHost()
    def hostNic = NetworkInterface.getByInetAddress(hostAddress)
    hostNic.getHardwareAddress().each { mac << String.format("%02X", it) }
    String ret = mac.join(':')
    logger.debug "getMacAddress: HOST:${hostAddress.getCanonicalHostName()} IP:${hostAddress.getHostAddress()} IfName:${hostNic.getName()} Mac:${ret}"
    ret
  }

  // Gen Report
  def makeReport(target, item, value) {
    def report = [target: target, item: item, value: value, level:null]
    // TODO set level.
    report
  }


  //////// Control Actions.

  // keepAlive
  def keepAlive(req) {
    config.reportkey = req.reportkey
    [status: 'ok', reportkey: config.reportkey]
  }

  // update
  def updateReporter(req) {
    newobj.each { key, val -> config[key] = val }
    // TODO persist
    if (config.persist) logger.info "TODO. persist"
    [status:'ok', Reporter:config]
  }

  // reporter control hander. call nonmatchHandler when message cannot recoginized.
  def control(msg, nonmatchHandler) {
    try {
      msg.reply("${msg.body.action}"(req))
    } catch (MissingMethodException mme) {
      nonmatchHandler.call(msg)
    } catch (Exception e) {
      logger.fatal "${e.getClass()}: ${e.getMessage()}"
      logger.fatal "${e.getStackTrace()}"
      msg.reply([status:'error', 'message':'internal error.'])
    }
  }

  // send report to receiver-report.
  def sendReport(worktime, reports) {
    logger.debug "${this.class}#sendReport:"
    def report = [action:'registerReport',
                  date: System.currentTimeMillis(),
                  worktime: worktime,
                  reporter: [id: config.id, reportkey:config.reportkey],
                  reports: reports]
    logger.trace "${this.class} send No.${sendreport} report(${report}) to ${config.receiver}."
    // TODO receive check
    vertx.eventBus.send(config.receiver, report) {
      if (it.body.status != 'ok') logger.warn "Report is not received. Caused by (${it.body.message})"
      else logger.debug "report No.${sendreport} received correctly."
    }
    ++sendreport // increment number of report
  }

  // register me.
  def register() {
    logger.debug "${this.class}#register:"

    // start timeout timer
    def timerID = vertx.setTimer(config.timeout) {
      // retry when timeout.
      logger.info "Timeout. retry registering..."
      register()
    }

    def msg = [action:'registerReporter', reporter:[id:config.id, name: config.name, mac:config.mac]]
    vertx.eventBus.send(ADR_REG_REPORTER, msg) {
      def reply = it.body
      if (reply.status != 'ok') {
        logger.warn "Cannot register. Caused by ${reply.message}"
      } else {
        // stop timeout timer.
        vertx.cancelTimer(timerID)

        // set information
        config.domain = reply.reporter.domain
        config.id = reply.reporter.id
        config.name = reply.reporter.name
        config.receiver = reply.reporter.receiver    // eventbus address that listen by receiver-report
        config.reportkey = reply.reporter.reportkey
        address = "reporter.${config.domain}.${config.id}"
        logger.debug "DOMAIN:${config.domain}, ID:${config.id}, NAME:${config.name}, RECEIVER:${config.receiver}, KEY:${config.reportkey}"

        // TODO persist information.
        if (config.persist) logger.info "TODO. persist"

        // start control eventbus listen
        vertx.eventBus.registerHandler(address) { control(it) }

        // start report
        startReporting()
      }
    }
  }

  @Override def start() {
    super.start()
    starttime = System.currentTimeMillis() // save start date
    sendreport = 0
    config.mac = getMacAddress()
  }
}
