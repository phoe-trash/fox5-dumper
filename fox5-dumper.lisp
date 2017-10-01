;;;; fox5-dumper.lisp

(in-package #:fox5-dumper)

(defparameter +help+
  "FOX5 walkable dumper library.
Based on Raptor FOX5 library by Michał \"phoe\" Herda.

Provided a FOX5 file, prints a list of all objects inside that FOX5 file
and whether they have the walkable flag set, in the following format:

0 0
1 0
2 0
3 1
4 1
5 0
...")

(defvar *id* -1)

(defun dump-walkables (fox5)
  (dolist (object (fox5::children fox5))
    (let* ((boundp (slot-boundp object 'fox5::%object-id))
           (id (if boundp (fox5::object-id object) (incf *id*)))
           (flags (fox5::flags object))
           (walkablep (if (member :walkable flags) 1  0)))
      (format t "~D ~D~%" id walkablep))))

(defun program-function (filename &key help)
  (cond (help (princ +help+))
        (t (let ((fox5 (fox5::read-fox5 filename nil)))
             (dump-walkables fox5)))))

(defun main ()
  (let ((args command-line-arguments:*command-line-arguments*))
    (handle-command-line
     '()
     #'program-function
     :command-line args
     :name "FOX5 walkability dumper"
     :positional-arity 1)))

(defun close-hook ()
  (let ((libraries (cffi:list-foreign-libraries)))
    (mapc #'cffi:close-foreign-library libraries)))

(pushnew 'close-hook uiop/image:*image-dump-hook*)

(defun load-hook ()
  (cffi:load-foreign-library
   (concatenate 'string "./"
                #+(and x86 darwin) "lzma-mac32.dylib"
                #+(and x86 unix) "lzma-lin32.so"
                #+(and x86 windows) "lzma-win32.dll"
                #+(and x86-64 darwin) "lzma-mac64.dylib"
                #+(and x86-64 unix) "lzma-lin64.so"
                #+(and x86-64 windows) "lzma-win64.dll"))
  (setf cl-lzma::*alloc-functions*
        (let* ((ptr (cffi:foreign-alloc :pointer :count 2))
               (struct (cl-lzma::make-i-sz-alloc :ptr ptr)))
          (setf (cl-lzma::i-sz-alloc.alloc struct)
                (autowrap:callback 'cl-lzma::lzma-alloc)
                (cl-lzma::i-sz-alloc.free struct)
                (autowrap:callback 'cl-lzma::lzma-free))
          struct)))

(pushnew 'load-hook uiop/image:*image-prelude*)

(defun debug-hook (condition debugger-hook)
  (trivial-backtrace:print-backtrace condition))

(defvar *hookedp* nil)

(unless *hookedp*
  (setf *hookedp* t
        *debugger-hook* #'debug-hook))

(setf uiop/image:*image-entry-point* 'main)

(defun dump (filename)
  (uiop:dump-image filename :executable t
                            #+sbcl :compression #+sbcl t))
