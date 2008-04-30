(cl:defpackage #:redshank
  (:nicknames #:clee)
  (:use #:cl)
  (:export #:free-vars-for-emacs
           #:values-for-emacs
           
           #:find-free-variables
           #:find-variables
           
           #:tree-walk))

(cl:in-package #:redshank)

#+sbcl
(eval-when (:compile-toplevel :load-toplevel :execute)
  (require :sb-cltl2))


(defun tree-walk (tree fn &key key)
  (subst-if nil (constantly nil) tree
            :key (lambda (sub-tree)
                   (funcall fn (funcall (or key #'identity) sub-tree)))))

(defun find-variables (form &optional env)
  (let ((vars '()))
    (flet ((record-variable (x)
             (when (and (symbolp x)
                        (not (constantp x env)))
               (pushnew x vars))))
      (tree-walk form #'record-variable))
    vars))

(defun macroexpand-all (form &optional env)
  (declare (ignorable env))
  #+sbcl (sb-cltl2:macroexpand-all form env)
  #-sbcl (swank::macroexpand-all form))

(defun special-variable-p (symbol &optional env)
  (declare (ignorable symbol env))
  (eql (or #+sbcl (sb-cltl2:variable-information symbol env))
       :special))

(defmacro %extract-variable (variable specials)
  (declare (special *free-variables*))
  (when (or specials
            (not (special-variable-p variable)))
    (pushnew variable *free-variables*))
  (gensym))

(defun find-free-variables (form &key env (specials t))
  (let ((bindings (loop for v in (find-variables form env)
                        collect (list v `(%extract-variable ,v ,specials))))
        (*free-variables* '()))
    (declare (special *free-variables*))
    ;; macro-expanding picks up free variables as side effect
    (macroexpand-all `(symbol-macrolet ,bindings ,form) env)
    *free-variables*))

(defun values-for-emacs (list &optional package)
  (with-standard-io-syntax
   (let ((*print-case* :downcase)
         (*print-readably* nil)
         (*print-pretty* nil)
         (*package* (or package *package*)))
     (mapcar #'prin1-to-string list))))

(defun free-vars-for-emacs (form-string package &key env specials)
  (let* ((form (swank::from-string form-string))
         (free-vars (reverse (find-free-variables form :env env
                                                  :specials specials))))
    (values-for-emacs free-vars (find-package (string-upcase package)))))

#||
[Tue Nov  6 14:30:03 CET 2007]
<jsnell> michaelw: the way I did things when writing a prototype for a
          slime-extract-defun was somewhat different. I'm not sure whether it
          was better on the whole, but it had at least a couple of benefits
          over this approach
<michaelw> jsnell: I'm interested
<jsnell> to find the set of parameters that would need to be passed, I'd
          programatically rewrite the source to wrap the extracted region in a
          (%extract-environment ...) macro
-:- the-crying-man [n=user@c-24-7-212-11.hsd1.il.comcast.net] has joined #lisp
<jsnell> and that would then be able to look at the actual compiler
          environment at the call site
<jsnell> so instead of doing the gensym-recording thing for all variables, I'd
          just do it for the exact set of variables that are actually visible
<michaelw> jsnell: do you have that code still around?
<jsnell> not easily accessible. I should be able to get to it in a couple of
          weeks
<michaelw> jsnell: can you say something about the benefits?
<jsnell> one thing is that it gives you access to local functions
<jsnell> another is that it works even if the symbol naming a variable isn't
          present in the subform you're extracting
<jsnell> but instead is generated by a macro
<michaelw> I see
<jsnell> but maybe those don't matter too much
<jsnell> it still fails with extracting code that depends on local macrolets,
          so...
||#