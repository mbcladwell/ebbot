(define-module (babweb lib twitter-oauth1) 
#:use-module (babweb lib env)
 #:use-module (web client)
 #:use-module (srfi srfi-19) ;; date time
 #:use-module (srfi srfi-1)  ;;list searching; delete-duplicates in list 
 #:use-module (srfi srfi-9)  ;;records
 #:use-module (web response)
 #:use-module (web request)
 #:use-module (oop goops) ;; class-of
 #:use-module (web uri)
 #:use-module (web client)
 #:use-module (web http)
 #:use-module (ice-9 rdelim)
 #:use-module (ice-9 i18n)   ;; internationalization
 #:use-module (ice-9 popen)
 #:use-module (ice-9 regex) ;;list-matches
 #:use-module (ice-9 receive)	     
 #:use-module (ice-9 string-fun)  ;;string-replace-substring
 #:use-module (ice-9 pretty-print)
 #:use-module (json)
 #:use-module (oauth oauth1)
 #:use-module (oauth oauth2)
 #:use-module (oauth oauth2 request)
 #:use-module (oauth oauth2 response)
 #:use-module (oauth utils)
 #:use-module (oauth request)
 #:use-module (oauth oauth1 client)
 #:use-module (oauth oauth1 utils)
 #:use-module (oauth oauth1 credentials)
 #:use-module (oauth oauth1 signature)
 #:use-module (rnrs bytevectors)
 #:use-module (ice-9 textual-ports)
 #:use-module (babweb lib image)
 #:use-module (babweb lib utilities)
 #:export ( main
	   ))


(define-record-type <response-token>
  (make-response-token token_type access_token)
  response-token?
  (token_type response-token-type)
  (access_token response-token-access-token))

(define oauth-response-token-record (make-response-token "bearer" *oauth-access-token* ))

;#<<oauth1-response> token: "856105513800609792-ttQfcoxgrGJnwaLfjEdyagDjL9lfbTP" secret: "EfoSSaCHSnmfkhfU2r5oiU03cA6Kb6SLLAr7rxZO73Tfg" params: (("user_id" . "856105513800609792") ("screen_name" . "mbcladwell"))>


;; Client credentials:

;;     App Key === API Key === Consumer API Key === Consumer Key === Customer Key === oauth_consumer_key
;;     App Key Secret === API Secret Key === Consumer Secret === Consumer Key === Customer Key === oauth_consumer_secret
;;     Callback URL === oauth_callback
     

;; Temporary credentials:

;;     Request Token === oauth_token
;;     Request Token Secret === oauth_token_secret
;;     oauth_verifier
     

;; Token credentials:

;;     Access token === Token === resulting oauth_token
;;     Access token secret === Token Secret === resulting oauth_token_secret


(define (get-request-token k s)
;;(define (get-request-token )
  ;; returns a response: #<<oauth1-response> token: "Ia2k4gAAAAABb11DAAABgJn1fzQ" secret: "Pi8PTBLsyuE7tsfB1X2anChF3WyP1R7e" params: ()>
  ;; retrieve with  token: (oauth1-response-token a)
  ;;                secret: (oauth1-response-token-secret a)
  (let*( (uri "https://api.twitter.com/oauth/request_token")
	 ;;(credentials (make-oauth1-credentials oauth-access-token oauth-token-secret))
	 (credentials (make-oauth1-credentials k s))	 
;;	 (credentials (make-oauth1-credentials *oauth-consumer-key* *oauth-consumer-secret*))	 
;;	 (a  (oauth1-client-request-token uri credentials "oob"    ;;for pin
	 (a  (oauth1-client-request-token uri credentials "https://build-a-bot.biz/bab/register2.php"
					 #:method 'POST
					 #:params '()
					 #:signature oauth1-signature-hmac-sha1)))	
  a))


;; (define (get-pin rt)
;; ;;rt is the request token provided by get-request-token
;;   (let* ((uri (string-append "https://api.twitter.com/oauth/authenticate?oauth_token=" rt))
;;          (out (receive (response body)
;; 		   (oauth1-http-request verifier-request #:body #f #:extra-headers '((oauth_callback_confirmed . "true")))
;; 		(oauth1-http-body->response response body))))
;;     #f

	 
;;        ))
  
  

(define (get-access-token oauth_tokenv oauth-verifierv)
  ;;oauth_token is the token from get-request-token
  ;;oauth-verifier is the pin manually copied from the ____ page
  ;;output is a 'response object' as with get-request-token
  (let* ((_ (pretty-print (string-append "guile -L /home/mbc/projects/babweb -L /home/mbc/projects/guile-oauth -e '(babweb lib twitter)' -s /home/mbc/projects/babweb/babweb/lib/twitter.scm " oauth_tokenv " " oauth-verifierv)))
	 (_ (pretty-print (string-append "in get-access-token: " oauth-verifierv)))
	 (uri "https://api.twitter.com/oauth/access_token")
	 (verifier-request (make-oauth-request uri 'POST '()))
	  (dummy (oauth-request-add-params verifier-request `( (oauth_token . ,oauth_tokenv)
	  						       (oauth_verifier . ,oauth-verifierv)
							      (oauth_callback_confirmed . "true")
							       )))
	                                                       
	  (out (receive (response body)
;;		   (oauth1-http-request verifier-request #:body #f #:extra-headers '((oauth_callback_confirmed . "true")))
		   (oauth1-http-request verifier-request #:body #f )
		 (oauth1-http-body->response response body)))
	  (_ (pretty-print "end-of-get-access-token"))
	  )    
    out
;; (receive (response body)
;; 	   	   (oauth1-http-request verifier-request #:body #f #:extra-headers '((oauth_callback_confirmed . "true")))
;; 	  	 (pretty-print (utf8->string body)))
    ))

;#<<oauth1-response> token: "856105513800609792-ttQfcoxgrGJnwaLfjEdyagDjL9lfbTP" secret: "EfoSSaCHSnmfkhfU2r5oiU03cA6Kb6SLLAr7rxZO73Tfg" params: (("user_id" . "856105513800609792") ("screen_name" . "mbcladwell"))>


;;                              key                                 secret                            custid
;;guile -e main -s ./get-access-token.scm 2R103u4mp3iwy8MtjRY5LJXsw Cl5Jx2XRgYvo4GmXT7uZooq8jkXUiyYxwhCOVcd6RqF4LyMP0J eddibbot
;;#<<oauth1-response> token: "856105513800609792-afMxtRwKgu6gmq2TH9ScCAFav5kH1FA" secret: "QhqicaaTpMAe8UYTb0kUO41WwROHav3lCqo132cXZNEVG" params: (("user_id" . "856105513800609792") ("screen_name" . "mbcladwell"))>


;;(define (get-user-data oauth_tokenv oauth-verifierv)
 ;;oauth_token is the token from get-request-token
  ;;oauth-verifier is the pin manually copied from the ____ page
  ;;output is a 'response object' as with get-request-token
(define (get-user-data oauth-verifier access-token)
  ;;access-token contains token, tokensecret
  ;;what is oauthVerifier inTwittService? comes from https://api.twitter.com/oauth/authenticate
  ;;so looks like the PIN
  (let* ((tokenv (oauth1-response-token access-token))
	 (secretv (oauth1-response-token-secret access-token))
	 (user-data-request (make-oauth-request "https://api.twitter.com/1.1/account/verify_credentials.json" 'GET '()))
	 (_ (oauth-request-add-params user-data-request `((oauth_consumer_key . ,*oauth-consumer-key*)
							  (oauth_nonce . ,(get-nonce 42 ""))
							  (oauth_timestamp . ,(oauth1-timestamp))
							  (oauth_token . ,tokenv)
							  (oauth_version . "1.0")					 
							  )))
	                                                       
	  (out (receive (response body)
		   (oauth1-http-request user-data-request #:body #f				
					#:signature oauth1-signature-hmac-sha1
					#:extra-headers '((access_token_secret . ,secretv)))
		 (oauth1-http-body->response response body)))
	  )    
    out
;; (receive (response body)
;; 	   	   (oauth1-http-request verifier-request #:body #f #:extra-headers '((oauth_callback_confirmed . "true")))
;; 	  	 (pretty-print (utf8->string body)))
    ))







(define (oauth1-post-tweet  text reply-id media-id)
  ;;https://developer.twitter.com/en/docs/authentication/oauth-1-0a/authorizing-a-request
  ;;https://developer.twitter.com/en/docs/authentication/oauth-1-0a/creating-a-signature
  (let* (
	 (oauth1-response (make-oauth1-response *oauth-access-token* *oauth-token-secret* '(("user_id" . "1516431938848006149") ("screen_name" . "eddiebbot")))) ;;these credentials do not change
	 (credentials (make-oauth1-credentials *oauth-consumer-key* *oauth-consumer-secret*))
 	 (uri  "https://api.twitter.com/2/tweets")
	 (tweet-request (make-oauth-request uri 'POST '()))
	 ;;(_ (pretty-print *oauth-consumer-secret*))
	 (dummy (oauth-request-add-params tweet-request `( 
	  						   (oauth_consumer_key . ,*oauth-consumer-key*)
							   (oauth_nonce . ,(get-nonce 20 ""))
							   (oauth_timestamp . ,(oauth1-timestamp))
							   (oauth_token . ,*oauth-access-token*)
							   (oauth_version . "1.0")
							   (status . ,text)
							   ) ))
	 (dummy (if (string=? reply-id "") #f (oauth-request-add-param tweet-request 'in_reply_to_status_id reply-id) ))
	 (dummy (if (string=? media-id "") #f (oauth-request-add-param tweet-request 'media_ids media-id) ))
	 (dummy (oauth1-request-sign tweet-request credentials oauth1-response #:signature oauth1-signature-hmac-sha1)))
    (oauth1-http-request tweet-request #:body #f #:extra-headers '())))


(define (oauth1-post-tweet-recurse lst reply-id media-id counter)
  ;;list of tweets to post
  ;;reply-id initially ""
  ;;counter initially 0; counter is needed to identify reply-id in first round and use media-id if exists
  (if (null? (cdr lst))
      (oauth1-post-tweet (car lst) reply-id "")
      (if (eqv? counter 0)
	  (begin
	    (receive (response body)	  
		(oauth1-post-tweet (car lst) reply-id media-id)
	      (set! counter (+ counter 1))
	      ;; (pretty-print (cdr lst))
	      ;; (pretty-print (assoc-ref  (json-string->scm (utf8->string body)) "id_str"))
	      ;; (pretty-print media-id)
	      ;; (pretty-print counter)

	     (oauth1-post-tweet-recurse  (cdr lst) (assoc-ref  (json-string->scm (utf8->string body)) "id_str")  media-id counter))			
	     )
	  (begin
	    (receive (response body)	  
		(oauth1-post-tweet (car lst) reply-id "")
	       (set! counter (+ counter 1))
	     (oauth1-post-tweet-recurse  (cdr lst) (assoc-ref  (json-string->scm (utf8->string body)) "id_str")  "" counter))			
	      ))  ))
       

;; guile -L /home/mbc/projects/babweb  -e '(babweb lib twitter)' -s /home/mbc/projects/babweb/babweb/lib/twitter.scm 
(define (main args)
  ;;arg1 is consumer_key
  ;;arg2 is consumer_secret
  ;;arg3 is customer id
  (let* (
	 ;; (token (oauth1-response-token (get-request-token (cadr args) (caddr args))))
	 (_  (pretty-print (string-append "in twitt: " *oauth-consumer-key*)))
	 (token (oauth1-response-token (get-request-token *oauth-consumer-key* *oauth-consumer-secret* )))
	  (uri (string-append "https://api.twitter.com/oauth/authenticate?oauth_token=" token))
	   (dummy (pretty-print uri))
	   (dummy (activate-readline))
	   (pin (readline "\nEnter pin: "))
	 ;; (oauth1-response (get-access-token token pin))  ;;user-id and screenname are the customer
	  (oauth1-response (get-access-token (cadr args) (caddr args)))  ;;user-id and screenname are the customer
	  ;; (token (oauth1-response-token oauth1-response))
	  ;; (secret (oauth1-response-token-secret oauth1-response))
	  ;; (params (oauth1-response-params oauth1-response))
	  ;; (a (car params))
	  ;; (b (cadr params))
	  ;; (lst `((token . ,token)(secret . ,secret) ,a ,b))
	  ;; (p  (open-output-file  (string-append "./tokens/" (cadddr args) ".json")))
	  )
    
;;         (scm->json lst p)
	  
    
    (pretty-print oauth1-response)
    ) )

