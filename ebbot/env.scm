(define-module (babweb lib env) 
#:use-module (srfi srfi-19) ;; date time
#:use-module (srfi srfi-98) ;; env vars
#:use-module (srfi srfi-1)  ;;list searching; delete-duplicates in list 
#:use-module (ice-9 rdelim)
#:use-module (ice-9 popen)
#:use-module (ice-9 regex) ;;list-matches
#:use-module (ice-9 pretty-print)
#:use-module (ice-9 binary-ports)
#:use-module (json)
#:use-module (rnrs bytevectors)
#:use-module (rnrs io ports)
;#:use-module (ice-9 textual-ports)
#:use-module (gcrypt base64)
#:use-module (babweb lib utilities)
#:export ( 
	  *oauth-consumer-key*
	  *oauth-consumer-secret*
	  *bearer-token*
	  *oauth-access-token*
	  *oauth-token-secret*
	  *client-id*
	  *client-secret*
	  *tweet-length*
	  *working-dir*
	  *data-dir*
	  *redirecturi*
	  *platform*
	  *gpg-key*
	  convert-to-encrypted
	  main
	  ))

;;working-dir determined by starting dir

(define *oauth-consumer-key* #f)
(define *oauth-consumer-secret* #f)
(define *bearer-token* #f)
(define *oauth-access-token* #f)
(define *oauth-token-secret* #f)
(define *client-id* #f)
(define *client-secret* #f)
(define *working-dir* (getcwd))
(define *tweet-length* #f)
(define *redirecturi* #f)
(define *data-dir* #f)
(define *platform* #f)
(define *gpg-key* "babweb@build-a-bot.biz")


;;(define (get-envs)
  ;; (let*  ((varlst (if (access?  "./env.txt" R_OK)
  ;; 		      (let* ((p  (open-input-file  "./env.txt"))
  ;; 			     (a (get-string-all p))
  ;; 			     (b (base64-decode a)))
  ;; 			(json-string->scm (utf8->string b)))
  ;; 		      '(("tweet-length" . "0")("client-secret"  .  "null")
  ;; 			("client-id"  .  "null")("oauth-token-secret"  .  "null")("oauth-access-token"  .  "null")
  ;; 			("bearer-token"  .  "null")("oauth-consumer-secret"  .  "null")("oauth-consumer-key"  .  "null")))    ))

 (let*  ((varlst (if (access?  "./envs" R_OK)
		     (let* ((out-file (get-rand-file-name "f" "txt"))
			    (command  (string-append "gpg --output " out-file " --decrypt envs"))
			    (_ (system command))
			    (p  (open-input-file  out-file))
			    (a (get-string-all p))
			    (b (json-string->scm  a))
			    (_ (delete-file out-file)))
		       b)
		      '(("tweet-length" . "0")("client-secret"  .  "null")("data-dir"  .  "null")
			("client-id"  .  "null")("oauth-token-secret"  .  "null")("oauth-access-token"  .  "null")
			("bearer-token"  .  "null")("oauth-consumer-secret"  .  "null")("oauth-consumer-key"  .  "null")
			("redirecturi"  .  "null")("platform"  .  "null")("gpg-key"  .  "null"))
		      )    ))    
    (begin
      (set! *oauth-consumer-key* (assoc-ref varlst "oauth-consumer-key"))
      (set! *oauth-consumer-secret* (assoc-ref varlst "oauth-consumer-secret"))
      (set! *bearer-token* (assoc-ref varlst "bearer-token"))
      (set! *oauth-access-token* (assoc-ref varlst "oauth-access-token"))
      (set! *oauth-token-secret* (assoc-ref varlst "oauth-token-secret"))
      (set! *client-id* (assoc-ref varlst "client-id"))
      (set! *client-secret* (assoc-ref varlst "client-secret"))
      (set! *redirecturi* (assoc-ref varlst "redirecturi"))
      (set! *platform* (assoc-ref varlst "platform"))
      (set! *data-dir* (assoc-ref varlst "data-dir"))
      (set! *tweet-length* (if (assoc-ref varlst "tweet-length")			    
			       (string->number (assoc-ref varlst "tweet-length"))
			       #f))

      ;;   (set! *oauth-consumer-key* (get-environment-variable "CONSUMER_KEY"))
      ;; (set! *oauth-consumer-secret* (get-environment-variable "CONSUMER_SECRET"))
      ;; (set! *bearer-token* (get-environment-variable "BEARER_TOKEN"))
      ;; (set! *oauth-access-token* (get-environment-variable "ACCESS_TOKEN"))
      ;; (set! *oauth-token-secret* (get-environment-variable "TOKEN_SECRET"))
      ;; (set! *client-id* (get-environment-variable "CLIENT_ID"))
      ;; (set! *client-secret* (get-environment-variable "CLIENT_SECRET")))
      ;; (pretty-print (string-append "in env.scm: " *oauth-consumer-key*))

    ))


;;guix shell --manifest=manifest.scm -- guile -L /home/mbc/projects/ebbot  -e '(ebbot env)' -s /home/mbc/projects/ebbot/ebbot/env.scm env-clear.txt env.txt

;;guile -L /home/mbc/projects/babweb -e '(babweb lib env)' -s /home/mbc/projects/babweb/babweb/lib/env.scm env-clear-template.txt env.txt

;;(define (convert-to-encrypted fin fout)
;; (define (main args)
;;   (let* ((fin (cadr args))
;; 	 (fout (caddr args))
;; 	 (p  (open-input-file fin))
;; 	 (bytes64  (base64-encode (get-bytevector-all p)))
;; 	 (dummy (close-port p))
;; 	 (p2  (open-output-file fout))	
;; 	)	
;;     (put-string p2 bytes64)))

;;guile -L /home/mbc/projects/babweb -e '(babweb lib env)' -s /home/mbc/projects/babweb/babweb/lib/env.scm env-clear-template.txt
(define (main args)
  (let* ((fin (cadr args))
	 (p  (open-input-file fin))
	 (command (string-append "gpg --output envs --encrypt --recipient " *gpg-key* " " fin))
	 (_ (system command))
	 )
    (close-port p)
    ))

;;with everything in the store, you must place a subdir ebbot with env.scm which then has
;;to be first in GUILE_LOAD_PATH ::   export GUILE_LOAD_PATH="/home/mbc/projects/mastsoc/test${GUILE_LOAD_PATH:+:}$GUILE_LOAD_PATH"x
;;guix shell --manifest=manifest.scm -- guile  -e '(ebbot mastsoc)' -s /home/mbc/.guix-profile/share/guile/site/3.0/ebbot/mastsoc.scm

;;gpg --output envs --encrypt --recipient babweb@build-a-bot.biz env-clear-template.txt
;;gpg --output e-clear.txt --decrypt envs
