#' Create a linreg object
#' @param formula formula for linear model
#' @param data the dataset provided
#' @field formula, formla for the linear model
#' @field data, the dataset provided
#' @field m_X, the matrix of explanatory variables
#' @field m_Y, the matrix of dependent variable
#' @field X_t, transpose of m_X
#' @field XtX, inverse of matrix multiplication of m_X and X_t
#' @field betaestimates, estimates of the parameters
#' @field yfit, estimated y values
#' @field residual, residuals computed by subtracting yfit from actual y values
#' @field nparameters, number of parameters
#' @field residualvariance, variance of the residuals
#' @field residualstd, standard deviation of residuals
#' @field betavariance, variance of beta estimates
#' @field bb, diagonal of betavariance matrix
#' @field tvalues, comptued t values per parameter
#' @field pvalues, pvalues computed according to tvalues and pt function
#' @field standardizedresiduals, standardized residuals
#' @field sqrtresiduals, the square root of standardizedresiduals
#' @return empty
#' @importFrom ggplot2 theme_linedraw theme element_blank element_text stat_summary ggtitle xlab scale_x_continuous
#' @export linreg

linreg <- setRefClass("linreg",
                      fields = list(formula="formula",
                                    data="data.frame",
                                    m_X = "matrix",
                                    m_Y="matrix",
                                    Xt="matrix",
                                    XtX="matrix",
                                    betaestimates = "matrix",
                                    yfit="matrix",
                                    residual="matrix",
                                    nparameters = "integer",
                                    dof="integer",
                                    residualt = "matrix",
                                    residualvariance="numeric",
                                    residualstd = "numeric",
                                    betavariance = "matrix",
                                    bb = "numeric",
                                    tvalues="matrix",
                                    pvalues= "matrix",
                                    standardizedresiduals ="matrix",
                                    sqrtstresiduals = "matrix",
                                    export_formula = "formula",
                                    export_data = "character"
                                    ),
                      methods = list(
                        initialize = function(formula, data){
                          #Independent and dependent variables
                          m_X <<- model.matrix(formula, data)
                          m_Y <<- as.matrix(data[all.vars(formula)[1]])
                          # Transpose matrix X, and multiply + solve
                          Xt <<- t(m_X)
                          XtX <<- solve(Xt %*% m_X)
                          betaestimates <<- XtX %*% Xt %*% m_Y
                          # Estimate y
                          yfit <<- m_X %*% betaestimates
                          # Estimate residuals
                          residual <<- m_Y - yfit
                          # Determine degrees of freedom
                          nparameters <<- length(betaestimates)
                          dof <<- length(m_Y) - nparameters
                          # Variances
                          residualt <<- t(residual)
                          residualvariance <<- as.numeric((residualt %*% residual) / dof)
                          residualstd <<- sqrt(residualvariance)
                          betavariance <<- residualvariance * XtX
                          bb <<- diag(betavariance)
                          # t-values
                          tvalues <<- betaestimates/sqrt(bb)
                          # p-values
                          pvalues <<- 2 * pt(abs(tvalues), dof, lower.tail = FALSE)
                          # Standardized residuals for summary
                          standardizedresiduals <<- residual / sd(residual)
                          sqrtstresiduals <<- sqrt(abs(standardizedresiduals))

                          # saving names
                          export_formula <<- formula
                          export_data <<- deparse(substitute(data))
                        },
                        print = function(){
                          "Prints information about model"
                          cat(paste("linreg(formula = ", format(export_formula), ", data = ", export_data , ")\n\n ", sep = ""))
                          setNames(round(betaestimates[1:nrow(betaestimates)],3),rownames(betaestimates))
                        },
                        resid = function(){
                          return(as.vector(residual))
                        },
                        pred = function(){
                          return(yfit)
                        },
                        coef = function(){
                          vec <- as.vector(betaestimates)
                          names(vec) <- colnames(m_X)
                          return(vec)
                        },
                        plot = function(){
                          plot1 <- ggplot(data.frame(yfit, residual), aes(y=residual, x=yfit)) + geom_point(shape=21, size=3, colour="black", fill="white")
                          plot1 <- plot1 + theme_liu()

                          plot1 <- plot1 + stat_summary(fun.y=median, colour="red", geom="line", aes(group = 1))
                          plot1 <- plot1 + ggtitle("Residuals vs fitted") + xlab(paste("Fitted values \n lm(Petal.Length ~ Species)"))
                          plot2 <- ggplot(data.frame(yfit, sqrtstresiduals), aes(y=sqrtstresiduals, x=yfit)) + geom_point(alpha = 0.6, shape=21, size=3, colour="black", fill="white")
                          plot2 <- plot2 + theme_liu()
                          plot2 <- plot2 + stat_summary(fun.y=median, colour="red", geom="line", aes(group = 1))
                          plot2 <- plot2 + ggtitle("Scale-Location") + xlab(paste("Fitted values \n lm(Petal.Length ~ Species)"))
                          plot2 <- plot2 + scale_x_continuous(breaks = seq(0.0, 1.5, by= 0.5))

                          plotlist <- list(plot1, plot2)
                          return(plotlist)
                        },
                        summary = function(){
                          "Prints the summary of linear regression model."
                          cat(paste("linreg(formula = ", format(export_formula), ", data = ", export_data, ") :\n\n ", sep = ""))
                          x <- setNames(as.data.frame(cbind(betaestimates,as.matrix(sqrt(bb)),tvalues, formatC(pvalues, format = "e", digits = 2), p_star_cal(pvalues))), c("Coefficients","Standard error","t values", "p values", ""))
                          myPrint(x)
                          cat(paste("\n\nResidual standard error: ", residualstd, " on ", dof, " degrees of freedom: ", sep = ""))
                        }
                      ))

#' myPrint (custom print)
#'
#' Prints. This class can be used to print inside RC classes, which is not possible otherwise.
#'
#' @param x object
#' @param stripoff column names will be stripped off.
#'
#' @return Nothing.
myPrint = function(x, stripoff = FALSE) {
    print(x)
}

#' p_star_cal
#'
#' Returns * based on p value
#'
#' @param p_value the p_value.
#'
#' @return Returns: Signif. codes:  0 "***" 0.001 "**" 0.01 "*" 0.05 "." 0.1 " " 1
#'
p_star_cal = function(p_value) {
  x <- ifelse(p_value > 0.1, " ",
              (ifelse(p_value > 0.05, " . ",
                      (ifelse(p_value > 0.01, "*",
                              (ifelse(p_value > 0.001, "**","***")))))))
  return(x)
}
