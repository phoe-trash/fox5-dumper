;;;; fox5-dumper.asd

(asdf:defsystem #:fox5-dumper
  :description "Describe fox5-dumper here"
  :author "Michał \"phoe\" Herda <phoe@teknik.io>"
  :license "MIT"
  :serial t
  :depends-on (#:fox5
               #:command-line-arguments
               #:trivial-backtrace)
  :components ((:file "package")
               (:file "fox5-dumper")))
