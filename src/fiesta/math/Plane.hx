package fiesta.math;

/**
 * 3 dimensional plane
 */
class Plane extends Vector4 {
    public var normal:Vector4;
    public var distance:Float;
    public function new(?vec4:Vector4){
        super();
        if(vec4 != null){
            this.normal = vec4;
            this.distance = vec4.w;   
        } else {
            this.normal = new Vector4();
            this.distance = this.normal.w;
        }
    }

    /**
     * Copy the values from one plane to this
     * @param  {Plane} m the source plane
     * @return {Plane} this
     */
    public function copy(plane:Plane) {
        this.normal.copyFrom(plane.normal);
        this.distance = plane.distance;
        return this;
    }
}   