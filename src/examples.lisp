(in-package :cl-rabbit.examples)

(defun test-send ()
  (with-connection (conn)
    (let ((socket (tcp-socket-new conn)))
      (socket-open socket "localhost" 5672)
      (login-sasl-plain conn "/" "guest" "guest")
      (channel-open conn 1)
      (basic-publish conn 1
                     :exchange "test-ex"
                     :routing-key "xx"
                     :body (babel:string-to-octets "this is the message content" :encoding :utf-8)))))

(defun recv-loop (conn)
  (maybe-release-buffers conn)
  (consume-message conn))

(defun test-recv ()
  (with-connection (conn)
    (let ((socket (tcp-socket-new conn)))
      (socket-open socket "localhost" 5672)
      (login-sasl-plain conn "/" "guest" "guest" :properties '(("product" . "cl-rabbit")))
      (channel-open conn 1)
      (exchange-declare conn 1 "test-ex" "topic")
      (let ((queue-name (queue-declare conn 1 :auto-delete t)))
        (queue-bind conn 1 :queue queue-name :exchange "test-ex" :routing-key "xx")
        (basic-consume conn 1 queue-name)
        (let ((result (recv-loop conn)))
          (format t "Got message: ~s, content: ~s" result (babel:octets-to-string (message/body (envelope/message result))
                                                                                  :encoding :utf-8)))))))

(defun test-recv-in-thread ()
  (let ((out *standard-output*))
    (bordeaux-threads:make-thread #'(lambda ()
                                      (let ((*standard-output* out))
                                        (test-recv))))))
